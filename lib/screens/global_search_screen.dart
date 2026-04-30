import 'dart:async';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/products/product_edit_screen.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/ui/components/order_list_component.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

enum _SearchTab { orders, products, customers }

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _orderService = OrderService();
  final _productService = ProductService();
  final _customerService = CustomerService();

  Timer? _searchDebounce;
  String _lastSearchValue = '';
  _SearchTab _activeTab = _SearchTab.orders;

  List<Order> _orders = [];
  List<Product> _products = [];
  List<User> _customers = [];

  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentValue = _searchController.text.trim();
    if (currentValue == _lastSearchValue) return;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _lastSearchValue = currentValue;
      _performSearch(currentValue);
    });

    if (mounted) setState(() {});
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _orders = [];
        _products = [];
        _customers = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      switch (_activeTab) {
        case _SearchTab.orders:
          final result = await _orderService.globalSearch(query);
          if (!mounted) return;
          setState(() => _orders = result.data ?? []);
          break;
        case _SearchTab.products:
          final result = await _productService.list(search: query, perPage: 20);
          if (!mounted) return;
          setState(() => _products = result.data?.items ?? []);
          break;
        case _SearchTab.customers:
          final result = await _customerService.list(
            search: query,
            perPage: 20,
          );
          if (!mounted) return;
          setState(() => _customers = result.data?.items ?? []);
          break;
      }

      if (mounted) setState(() => _isSearching = false);
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Search error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Có lỗi xảy ra khi tìm kiếm';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tìm kiếm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isSearching) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildSearchResults()),
          _buildBottomBar(colorScheme, bottomInset),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme, double bottomInset) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final safePadding = bottomInset > 0
        ? 0.0
        : MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: safePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.applyOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<_SearchTab>(
              segments: [
                ButtonSegment(
                  value: _SearchTab.orders,
                  label: Text(
                    hasQuery ? 'Đơn hàng (${_orders.length})' : 'Đơn hàng',
                  ),
                ),
                ButtonSegment(
                  value: _SearchTab.products,
                  label: Text(
                    hasQuery ? 'Sản phẩm (${_products.length})' : 'Sản phẩm',
                  ),
                ),
                ButtonSegment(
                  value: _SearchTab.customers,
                  label: Text(
                    hasQuery ? 'Khách (${_customers.length})' : 'Khách hàng',
                  ),
                ),
              ],
              selected: {_activeTab},
              onSelectionChanged: (selected) {
                final newTab = selected.first;
                setState(() => _activeTab = newTab);
                final query = _searchController.text.trim();
                if (query.isEmpty) return;
                final needsFetch = switch (newTab) {
                  _SearchTab.orders => _orders.isEmpty,
                  _SearchTab.products => _products.isEmpty,
                  _SearchTab.customers => _customers.isEmpty,
                };
                if (needsFetch) _performSearch(query);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _lastSearchValue = _searchController.text.trim();
                _performSearch(_lastSearchValue);
              },
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa tìm kiếm...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _lastSearchValue = '';
                          _performSearch('');
                          _focusNode.requestFocus();
                        },
                      ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _performSearch(_searchController.text.trim()),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Nhập từ khóa để tìm kiếm',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Mã đơn hàng, tên sản phẩm, tên khách hàng...',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final activeCount = switch (_activeTab) {
      _SearchTab.orders => _orders.length,
      _SearchTab.products => _products.length,
      _SearchTab.customers => _customers.length,
    };
    if (_isSearching && activeCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (_activeTab) {
      _SearchTab.orders => _buildOrderResults(),
      _SearchTab.products => _buildProductResults(),
      _SearchTab.customers => _buildCustomerResults(),
    };
  }

  // -- Order results --

  Widget _buildOrderResults() {
    return OrderListComponent(
      orders: _orders,
      isLoading: false,
      currentPage: 1,
      totalPages: 1,
      viewMode: OrderListViewMode.full,
    );
  }

  // -- Product results --

  Widget _buildProductResults() {
    if (_products.isEmpty) return _buildEmptyState('sản phẩm');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductTile(_products[index]),
    );
  }

  Widget _buildProductTile(Product product) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final bestPrice = product.bestPrice ?? product.price;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductEditScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.applyOpacity(0.3),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              product.isActive
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: product.isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.sku != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.sku!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bestPrice > 0
                      ? CurrencyHelper.formatCurrency(bestPrice)
                      : '—',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kho: ${product.instock}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Customer results --

  Widget _buildCustomerResults() {
    if (_customers.isEmpty) return _buildEmptyState('khách hàng');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _customers.length,
      itemBuilder: (context, index) => _buildCustomerTile(_customers[index]),
    );
  }

  Widget _buildCustomerTile(User customer) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(userId: customer.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.applyOpacity(0.3),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (customer.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Text(
                customer.phone!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Shared --

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy $type',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử tìm với từ khóa khác',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
