import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/product/product_filter_provider.dart';
import 'package:fcode_pos/providers/product/product_list_provider.dart';
import 'package:fcode_pos/screens/products/product_edit_screen.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(productFilterProvider).search;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    ref.read(productFilterProvider.notifier).state = ProductFilter(
      search: value.trim(),
      page: 1,
    );
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

    return AppScaffold(
      title: 'Sản phẩm',
      enableSearch: true,
      searchHint: 'Tìm kiếm sản phẩm',
      searchController: _searchController,
      searchDebounce: const Duration(milliseconds: 550),
      onSearchChanged: _applySearch,
      onSearchSubmitted: _applySearch,
      body: (context, scrollController) => Column(
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _buildContent(
              scrollController: scrollController,
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
    required ScrollController scrollController,
    required List<Product> products,
    required bool isLoading,
    required bool hasData,
    required String? error,
    required int currentPage,
  }) {
    if (isLoading && !hasData && error == null) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, _) => const ProductListItemSkeleton(),
      );
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
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductListItem(
            product: product,
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
