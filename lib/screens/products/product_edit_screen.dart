import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/product_update_data.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/api/api_exception.dart';

class ProductEditScreen extends StatefulWidget {
  final Product product;
  const ProductEditScreen({super.key, required this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();
  bool _isLoading = false;
  String? _error;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _priceSaleController;
  late TextEditingController _instockController;
  late TextEditingController _expiryMonthController;
  bool _isActive = false;
  bool _allowBuyMulti = false;
  bool _requireAccount = false;
  bool _requirePassword = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _priceController = TextEditingController(text: p.price.toString());
    _priceSaleController = TextEditingController(
      text: p.priceSale?.toString() ?? '',
    );
    _instockController = TextEditingController(text: p.instock.toString());
    _expiryMonthController = TextEditingController(
      text: p.expiryMonth?.toString() ?? '',
    );
    _isActive = p.isActive;
    _allowBuyMulti = p.allowBuyMulti;
    _requireAccount = p.requireAccount;
    _requirePassword = p.requirePassword;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceSaleController.dispose();
    _instockController.dispose();
    _expiryMonthController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = ProductUpdateData(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      price: _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim()),
      priceSale: _priceSaleController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceSaleController.text.trim()),
      instock: _instockController.text.trim().isEmpty
          ? null
          : int.tryParse(_instockController.text.trim()),
      isActive: _isActive,
      allowBuyMulti: _allowBuyMulti,
      requireAccount: _requireAccount,
      requirePassword: _requirePassword,
      expiryMonth: _expiryMonthController.text.trim().isEmpty
          ? null
          : int.tryParse(_expiryMonthController.text.trim()),
    );
    try {
      await _service.update(data, widget.product.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Cập nhật thất bại.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật sản phẩm')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              // maxLength: 255,
              validator: (v) =>
                  v != null && v.length > 255 ? 'Tối đa 255 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Giá'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final value = double.tryParse(v);
                if (value == null || value < 0) return 'Giá phải >= 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceSaleController,
              decoration: const InputDecoration(labelText: 'Giá khuyến mãi'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final value = double.tryParse(v);
                final price = double.tryParse(_priceController.text);
                if (value == null || value < 0) {
                  return 'Giá khuyến mãi phải >= 0';
                }
                if (price != null && value >= price) {
                  return 'Giá khuyến mãi phải nhỏ hơn giá';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuantityInput(
                    labelText: 'Tồn kho',
                    controller: _instockController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final value = int.tryParse(v);
                      if (value == null || value < 0) {
                        return 'Tồn kho phải >= 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuantityInput(
                    controller: _expiryMonthController,
                    labelText: 'Tháng sử dụng',
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final value = int.tryParse(v);
                      if (value == null || value < 0) {
                        return 'Hạn sử dụng phải >= 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Kích hoạt'),
            ),
            SwitchListTile(
              value: _allowBuyMulti,
              onChanged: (v) => setState(() => _allowBuyMulti = v),
              title: const Text('Cho phép mua nhiều'),
            ),
            SwitchListTile(
              value: _requireAccount,
              onChanged: (v) => setState(() => _requireAccount = v),
              title: const Text('Yêu cầu tài khoản'),
            ),
            SwitchListTile(
              value: _requirePassword,
              onChanged: (v) => setState(() => _requirePassword = v),
              title: const Text('Yêu cầu mật khẩu'),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: LoadingIcon(
                icon: Icons.check_circle_outline_outlined,
                loading: _isLoading,
              ),
              label: Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
