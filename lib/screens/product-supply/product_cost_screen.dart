import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/product-supply/product_supply_form_screen.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

class ProductCostScreen extends StatefulWidget {
  const ProductCostScreen({super.key});

  @override
  State<ProductCostScreen> createState() => _ProductCostScreenState();
}

class _ProductCostScreenState extends State<ProductCostScreen> {
  final _productSupplyService = ProductSupplyService();
  final TextEditingController _searchController = TextEditingController();

  PaginatedData<ProductSupply>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _loadProductSupplies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return AppScaffold(
      title: 'Giá nhập',
      enableSearch: true,
      searchHint: 'Tìm sản phẩm hoặc nhà cung cấp',
      searchController: _searchController,
      onSearchChanged: (_) => _loadProductSupplies(page: 1),
      onSearchSubmitted: (_) => _loadProductSupplies(page: 1),
      actions: [
        IconButton(
          tooltip: 'Thêm giá nhập',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: _navigateToAddScreen,
        ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(items, scrollController)),
          _buildPaginationControls(pagination),
        ],
      ),
    );
  }

  Future<void> _navigateToAddScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ProductSupplyFormScreen()),
    );

    if (result == true && mounted) {
      _loadProductSupplies(page: _currentPage);
    }
  }

  Future<void> _navigateToEditScreen(ProductSupply productSupply) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ProductSupplyFormScreen(productSupply: productSupply),
      ),
    );

    if (result == true && mounted) {
      _loadProductSupplies(page: _currentPage);
    }
  }

  Widget _buildContent(List<ProductSupply> items, ScrollController scrollController) {
    if (_isLoading && _page == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
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
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.price_change_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu giá nhập',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProductSupplies(page: _currentPage),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _ProductSupplyTile(
            productSupply: item,
            onTap: () => _navigateToEditScreen(item),
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

class _ProductSupplyTile extends StatelessWidget {
  const _ProductSupplyTile({required this.productSupply, this.onTap});

  final ProductSupply productSupply;
  final VoidCallback? onTap;

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
    final sku = (productSupply.sku?.trim().isNotEmpty == true
        ? productSupply.sku!.trim()
        : productSupply.product?.sku?.trim().isNotEmpty == true
        ? productSupply.product!.sku!.trim()
        : null);
    final hasNote =
        productSupply.note != null && productSupply.note!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 12,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    supplyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (sku != null) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.qr_code_2_outlined,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    sku,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (hasNote) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      productSupply.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
