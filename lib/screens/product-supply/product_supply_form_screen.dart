import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/dropdown/product_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/supply_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:flutter/material.dart';

class ProductSupplyFormScreen extends StatefulWidget {
  const ProductSupplyFormScreen({super.key, this.productSupply});

  /// Nếu null thì là màn hình thêm mới, nếu có giá trị thì là màn hình chỉnh sửa
  final ProductSupply? productSupply;

  @override
  State<ProductSupplyFormScreen> createState() =>
      _ProductSupplyFormScreenState();
}

class _ProductSupplyFormScreenState extends State<ProductSupplyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productSupplyService = ProductSupplyService();

  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  final _noteController = TextEditingController();

  Product? _selectedProduct;
  Supply? _selectedSupply;
  bool _isPreferred = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.productSupply != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final ps = widget.productSupply!;
      _priceController.text = ps.price.toString();
      _skuController.text = ps.sku ?? '';
      _noteController.text = ps.note ?? '';
      _isPreferred = ps.isPreferred;
      _selectedProduct = ps.product;
      _selectedSupply = ps.supply;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      _showErrorSnackBar('Vui lòng chọn sản phẩm');
      return;
    }

    if (_selectedSupply == null) {
      _showErrorSnackBar('Vui lòng chọn nhà cung cấp');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = int.parse(
        _priceController.text.replaceAll(RegExp(r'[^\d]'), ''),
      );
      final sku = _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim();
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (_isEditMode) {
        await _productSupplyService.update(
          widget.productSupply!.id,
          _selectedProduct!.id,
          _selectedSupply!.id,
          price,
          sku: sku,
          note: note,
          isPreferred: _isPreferred,
        );
      } else {
        await _productSupplyService.create(
          _selectedProduct!.id,
          _selectedSupply!.id,
          price,
          sku: sku,
          note: note,
          isPreferred: _isPreferred,
        );
      }

      if (!mounted) return;

      _showSuccessSnackBar(
        _isEditMode
            ? 'Cập nhật giá nhập thành công'
            : 'Thêm giá nhập thành công',
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        _isEditMode ? 'Không thể cập nhật giá nhập' : 'Không thể thêm giá nhập',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _skuController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa giá nhập' : 'Thêm giá nhập'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleSubmit,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProductDropdown(),
              const SizedBox(height: 16),
              _buildSupplyDropdown(),
              const SizedBox(height: 16),
              _buildPriceField(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 24),
              _buildPreferredSwitch(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return ProductSearchDropdown(
      selectedProduct: _selectedProduct,
      isRequired: true,
      enabled: !_isEditMode,
      onChanged: (product) {
        setState(() => _selectedProduct = product);
      },
    );
  }

  Widget _buildSupplyDropdown() {
    return SupplyDropdown(
      selectedSupply: _selectedSupply,
      isRequired: true,
      enabled: !_isEditMode,
      onChanged: (supply) {
        setState(() => _selectedSupply = supply);
      },
    );
  }

  Widget _buildPriceField() {
    return MoneyFormField(
      controller: _priceController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập giá';
        }
        final price = int.tryParse(value);
        if (price == null || price <= 0) {
          return 'Giá phải lớn hơn 0';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSkuField() {
    return TextFormField(
      controller: _skuController,
      decoration: InputDecoration(
        labelText: 'Mã SKU',
        prefixIcon: const Icon(Icons.qr_code),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: 'Ghi chú',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPreferredSwitch() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        title: const Text('Nhà cung cấp ưu tiên'),
        subtitle: const Text(
          'Đánh dấu đây là nhà cung cấp ưu tiên cho sản phẩm này',
        ),
        value: _isPreferred,
        onChanged: (value) {
          setState(() => _isPreferred = value);
        },
        secondary: const Icon(Icons.star_outline),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _isSaving ? null : _handleSubmit,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check),
      label: Text(_isEditMode ? 'Cập nhật' : 'Thêm mới'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
