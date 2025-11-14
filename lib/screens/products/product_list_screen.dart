import 'dart:async';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/screens/products/product_edit_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  PaginatedData<Product>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      final currentValue = _searchController.text.trim();

      // Only trigger search if text actually changed
      if (currentValue == _lastSearchValue) {
        return;
      }
      _lastSearchValue = currentValue;
      _loadProducts(page: 1);
    });

    // Trigger rebuild so suffix icon visibility updates
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _productService.list(
        search: _searchController.text.trim(),
        page: page,
        perPage: _perPage,
      );

      if (!mounted) return;
      setState(() {
        _page = response.data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _page = null;
      });
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace, label: 'Load products error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách sản phẩm.';
        _page = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _page?.items ?? const <Product>[];
    final pagination = _page?.pagination;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          title: SearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm sản phẩm',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: _searchController.text.isEmpty
                ? null
                : [
                    IconButton(
                      tooltip: 'Xóa',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _loadProducts(page: 1);
                      },
                    ),
                  ],
            onSubmitted: (_) => _loadProducts(page: 1),
            textInputAction: TextInputAction.search,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent(products)),
            _buildPaginationControls(pagination),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Product> products) {
    if (_isLoading && _page == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadProducts(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không tìm thấy sản phẩm phù hợp'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return HuxCard(
            title: product.name,
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(product: product),
                ),
              );
              if (updated == true) {
                _loadProducts(page: _currentPage);
              }
            },
            child: _ProductCard(product: product),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(Pagination? pagination) {
    if (pagination == null || pagination.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text(
            'Trang ${pagination.currentPage}/${pagination.lastPage}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: !_isLoading && pagination.currentPage > 1
                ? () => _loadProducts(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadProducts(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bestPrice = product.bestPrice ?? product.price;
    final bestPriceLabel = bestPrice > 0
        ? CurrencyHelper.formatCurrency(bestPrice)
        : '—';
    final instockLabel = product.instock.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconValue(
              icon: Icons.price_change_outlined,
              value: bestPriceLabel,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 20),
            _IconValue(
              icon: Icons.inventory_2_outlined,
              value: instockLabel,
              color: colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _IconValue extends StatelessWidget {
  const _IconValue({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
