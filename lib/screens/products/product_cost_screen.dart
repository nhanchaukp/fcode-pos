import 'dart:async';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';

class ProductCostScreen extends StatefulWidget {
  const ProductCostScreen({super.key});

  @override
  State<ProductCostScreen> createState() => _ProductCostScreenState();
}

class _ProductCostScreenState extends State<ProductCostScreen> {
  final _productSupplyService = ProductSupplyService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  PaginatedData<ProductSupply>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProductSupplies();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentValue = _searchController.text.trim();

    // Only trigger search if text actually changed
    if (currentValue == _lastSearchValue) {
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _lastSearchValue = currentValue;
      _loadProductSupplies(page: 1);
    });

    // Update UI for suffix icon
    if (mounted) setState(() {});
  }

  Future<void> _loadProductSupplies({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _productSupplyService.list(
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
      debugPrintStack(
        stackTrace: stackTrace,
        label: 'Load product costs error: $e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải giá nhập sản phẩm.';
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
    final items = _page?.items ?? const <ProductSupply>[];
    final pagination = _page?.pagination;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          title: SearchBar(
            controller: _searchController,
            hintText: 'Tìm sản phẩm hoặc nhà cung cấp',
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
                        _loadProductSupplies(page: 1);
                      },
                    ),
                  ],
            onSubmitted: (_) => _loadProductSupplies(page: 1),
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
            Expanded(child: _buildContent(items)),
            _buildPaginationControls(pagination),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ProductSupply> items) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadProductSupplies(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.price_change_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có dữ liệu giá nhập'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProductSupplies(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ProductSupplyCard(productSupply: item);
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
                ? () => _loadProductSupplies(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadProductSupplies(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _ProductSupplyCard extends StatelessWidget {
  const _ProductSupplyCard({required this.productSupply});

  final ProductSupply productSupply;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priceLabel = CurrencyHelper.formatCurrency(productSupply.price);
    final productName = productSupply.product?.name.isNotEmpty == true
        ? productSupply.product!.name
        : 'Sản phẩm #${productSupply.productId}';
    final supplyName = productSupply.supply?.name.isNotEmpty == true
        ? productSupply.supply!.name
        : 'Nhà cung cấp #${productSupply.supplyId}';
    final updatedLabel = DateHelper.timeAgo(productSupply.updatedAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    supplyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cập nhật $updatedLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (productSupply.note != null && productSupply.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        productSupply.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
