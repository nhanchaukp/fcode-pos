import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

class ProductSearchDropdown extends StatefulWidget {
  final Product? selectedProduct;
  final Function(Product?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? Function(Product?)? validator;
  final String? labelText;

  const ProductSearchDropdown({
    this.selectedProduct,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.labelText,
    super.key,
  });

  @override
  State<ProductSearchDropdown> createState() => _ProductSearchDropdownState();
}

class _ProductSearchDropdownState extends State<ProductSearchDropdown> {
  final _productService = ProductService();
  final _textController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = false;
  Product? _selectedProduct;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.selectedProduct;
    if (_selectedProduct != null) {
      _textController.text = _selectedProduct!.name;
    }
    _loadProducts();
  }

  @override
  void didUpdateWidget(ProductSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProduct != oldWidget.selectedProduct) {
      setState(() {
        _selectedProduct = widget.selectedProduct;
        _textController.text = widget.selectedProduct?.name ?? '';
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _productService.list(perPage: 200);
      final items = response.data?.items ?? [];
      if (!mounted) return;
      setState(() {
        _products = items;
        // Nếu có selectedProduct, tìm lại trong danh sách để đảm bảo reference đúng
        if (_selectedProduct != null) {
          _selectedProduct = _products.firstWhere(
            (p) => p.id == _selectedProduct!.id,
            orElse: () => _selectedProduct!,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (!mounted) return;
      setState(() {
        _products = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelText =
        widget.labelText ?? 'Sản phẩm${widget.isRequired ? ' *' : ''}';

    if (_isLoading) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.inventory_2_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const SizedBox(
            width: 20,
            height: 20,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        enabled: false,
      );
    }

    return TextFormField(
      controller: _textController,
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.inventory_2_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: _errorText,
        suffixIcon: _selectedProduct != null && widget.enabled
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _selectedProduct = null;
                    _errorText = null;
                  });
                  widget.onChanged?.call(null);
                },
              )
            : null,
      ),
      onTap: widget.enabled
          ? () async {
              final selected = await showModalBottomSheet<Product>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return _ProductSelectSheet(
                    products: _products,
                    selected: _selectedProduct,
                  );
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedProduct = selected;
                  _textController.text = selected.name;
                  _errorText = null;
                });
                widget.onChanged?.call(selected);
              }
            }
          : null,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedProduct);
        } else if (widget.isRequired && _selectedProduct == null) {
          return 'Vui lòng chọn sản phẩm';
        }
        return null;
      },
    );
  }
}

class _ProductSelectSheet extends StatefulWidget {
  final List<Product> products;
  final Product? selected;
  const _ProductSelectSheet({required this.products, this.selected});

  @override
  State<_ProductSelectSheet> createState() => _ProductSelectSheetState();
}

class _ProductSelectSheetState extends State<_ProductSelectSheet> {
  late List<Product> _filtered;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.products;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = widget.products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            (product.sku?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _filtered.isEmpty
                    ? const Center(child: Text('Không có sản phẩm phù hợp'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final product = _filtered[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: product.sku != null
                                ? Text('SKU: ${product.sku}')
                                : null,
                            trailing: widget.selected?.id == product.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(product);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
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
