import 'dart:async';

import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/product/product_filter_provider.dart';
import 'package:fcode_pos/providers/product/product_list_provider.dart';
import 'package:fcode_pos/screens/products/product_edit_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(productFilterProvider);
    _searchController.text = currentFilter.search;
    _lastSearchValue = currentFilter.search;
    _searchController.addListener(_handleSearchChanged);
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
      if (currentValue == _lastSearchValue) return;
      _lastSearchValue = currentValue;
      ref.read(productFilterProvider.notifier).state = ProductFilter(
        search: currentValue,
        page: 1,
      );
    });

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final productListAsync = ref.watch(productListProvider);

    final isLoading = productListAsync.isLoading;
    final products = productListAsync.value?.items ?? const <Product>[];
    final pagination = productListAsync.value?.pagination;
    final error = productListAsync.hasError
        ? productListAsync.error.toString()
        : null;
    final hasData = productListAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SearchBar(
          controller: _searchController,
          hintText: 'Tìm kiếm sản phẩm',
          leading: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: _searchController.text.isEmpty
              ? null
              : [
                  IconButton(
                    tooltip: 'Xóa',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _lastSearchValue = '';
                      ref.read(productFilterProvider.notifier).state =
                          const ProductFilter(search: '', page: 1);
                    },
                  ),
                ],
          onSubmitted: (_) {
            final value = _searchController.text.trim();
            _lastSearchValue = value;
            ref.read(productFilterProvider.notifier).state = ProductFilter(
              search: value,
              page: 1,
            );
          },
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
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _buildContent(
              products: products,
              isLoading: isLoading,
              hasData: hasData,
              error: error,
              currentPage: filter.page,
            ),
          ),
          _buildPaginationControls(pagination, isLoading),
        ],
      ),
    );
  }

  Widget _buildContent({
    required List<Product> products,
    required bool isLoading,
    required bool hasData,
    required String? error,
    required int currentPage,
  }) {
    if (isLoading && !hasData && error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && !hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(productListProvider),
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
      onRefresh: () async => ref.invalidate(productListProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(product: product),
                ),
              );
              if (updated == true) {
                ref.invalidate(productListProvider);
              }
            },
            child: _ProductCard(product: product),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(Pagination? pagination, bool isLoading) {
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
            onPressed: !isLoading && pagination.currentPage > 1
                ? () {
                    ref.read(productFilterProvider.notifier).state = ref
                        .read(productFilterProvider)
                        .copyWith(page: pagination.currentPage - 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !isLoading && pagination.currentPage < pagination.lastPage
                ? () {
                    ref.read(productFilterProvider.notifier).state = ref
                        .read(productFilterProvider)
                        .copyWith(page: pagination.currentPage + 1);
                  }
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (product.sku != null) ...[
              Row(
                children: [
                  _IconValue(
                    icon: Icons.qr_code_2_outlined,
                    value: product.sku!,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Tooltip(
                  message: product.isActive ? 'Đang hoạt động' : 'Đã tạm dừng',
                  child: Icon(
                    product.isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: product.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),

                _IconValue(
                  icon: Icons.price_change_outlined,
                  value: bestPriceLabel,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _IconValue(
                  icon: Icons.inventory_2_outlined,
                  value: instockLabel,
                  color: colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
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
