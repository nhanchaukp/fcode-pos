import 'dart:async';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

class ProductSearchDropdown extends StatefulWidget {
  final Product? selectedProduct;
  final Function(Product) onProductSelected;
  final VoidCallback onProductCleared;

  const ProductSearchDropdown({
    this.selectedProduct,
    required this.onProductSelected,
    required this.onProductCleared,
    super.key,
  });

  @override
  State<ProductSearchDropdown> createState() => _ProductSearchDropdownState();
}

class _ProductSearchDropdownState extends State<ProductSearchDropdown> {
  late TextEditingController _searchController;
  final _productService = ProductService();
  List<Product> _allProducts = []; // Danh sách tất cả sản phẩm
  List<Product> _searchResults = []; // Danh sách sản phẩm sau khi filter
  bool _isLoading = false;
  Timer? _debounceTimer;
  Product? _currentSelectedProduct;

  @override
  void initState() {
    super.initState();
    _currentSelectedProduct = widget.selectedProduct;
    _searchController =
        TextEditingController(text: widget.selectedProduct?.name ?? '');
    _searchController.addListener(_onSearchChanged);
    _loadAllProducts(); // Load tất cả sản phẩm khi khởi tạo
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Load tất cả sản phẩm khi khởi tạo
  Future<void> _loadAllProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _productService.list(
        page: 1,
        perPage: 200, // Load nhiều sản phẩm
      );
      if (!mounted) return;
      setState(() {
        _allProducts = result.data;
        _searchResults = result.data; // Hiển thị tất cả ban đầu
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (!mounted) return;
      setState(() {
        _allProducts = [];
        _searchResults = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterProducts(_searchController.text);
    });
  }

  // Filter sản phẩm local thay vì gọi API
  void _filterProducts(String query) {
    if (!mounted) return;

    if (query.isEmpty) {
      // Hiển thị tất cả sản phẩm khi không có search query
      setState(() => _searchResults = _allProducts);
      return;
    }

    // Filter theo tên sản phẩm (case-insensitive)
    final filteredProducts = _allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() => _searchResults = filteredProducts);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Product>(
      controller: _searchController,
      enableSearch: true,
      requestFocusOnTap: true,
      onSelected: (Product? product) {
        if (product != null) {
          widget.onProductSelected(product);
          setState(() {
            _currentSelectedProduct = product;
            _searchController.text = product.name;
          });
        }
      },
      expandedInsets: EdgeInsets.zero,
      menuHeight: 300,
      dropdownMenuEntries: _buildDropdownEntries(),
      hintText: widget.selectedProduct?.name ?? 'Tìm sản phẩm',
      label: const Text('Sản phẩm'),
      leadingIcon: const Icon(Icons.inventory_2_outlined),
      trailingIcon: _currentSelectedProduct != null
          ? GestureDetector(
              onTap: () {
                _searchController.clear();
                widget.onProductCleared();
                setState(() {
                  _currentSelectedProduct = null;
                  _searchResults = _allProducts; // Reset về tất cả sản phẩm
                });
              },
              child: const Icon(Icons.close),
            )
          : null,
    );
  }

  List<DropdownMenuEntry<Product>> _buildDropdownEntries() {
    if (_isLoading) {
      return [
        DropdownMenuEntry<Product>(
          value: Product(
            id: 0,
            name: 'Đang tải...',
            slug: '',
            instock: 0,
            price: 0,
            tags: [],
          ),
          label: 'Đang tải...',
          enabled: false,
        )
      ];
    }

    if (_searchResults.isEmpty) {
      return [];
    }

    return _searchResults
        .map((product) => DropdownMenuEntry<Product>(
              value: product,
              label: product.name,
              leadingIcon: const Icon(Icons.inventory_2),
              labelWidget: _buildProductLabel(product),
            ))
        .toList();
  }

  Widget _buildProductLabel(Product product) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Text(
              CurrencyHelper.formatCurrency(product.price),
              style: TextStyle(
                color: product.priceSale != null ? Colors.grey : Colors.green,
                fontSize: 12,
                decoration: product.priceSale != null
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (product.priceSale != null) ...[
              const SizedBox(width: 8),
              Text(
                CurrencyHelper.formatCurrency(product.priceSale!),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              'Kho: ${product.instock}',
              style: TextStyle(
                color: product.instock > 0 ? Colors.blue : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
