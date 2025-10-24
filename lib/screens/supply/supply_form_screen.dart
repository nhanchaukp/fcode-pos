import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/supply_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

/// Screen for creating or updating a Supply
/// Only allows editing name and content fields
class SupplyFormScreen extends StatefulWidget {
  /// Supply to edit (null for create mode)
  final Supply? supply;

  const SupplyFormScreen({super.key, this.supply});

  @override
  State<SupplyFormScreen> createState() => _SupplyFormScreenState();
}

class _SupplyFormScreenState extends State<SupplyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _supplyService = SupplyService();

  bool _isLoading = false;
  bool get _isEditMode => widget.supply != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.supply!.name;
      _contentController.text = widget.supply!.content ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'content': _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
      };

      if (_isEditMode) {
        await _supplyService.update(widget.supply!.id, data);
        if (!mounted) return;
        Toastr.success('Cập nhật nhà cung cấp thành công');
      } else {
        await _supplyService.create(data);
        if (!mounted) return;
        Toastr.success('Tạo nhà cung cấp thành công');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving supply: $e');
      if (mounted) {
        Toastr.error('Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode ? 'Chỉnh sửa nhà cung cấp' : 'Thêm nhà cung cấp',
          ),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildNameField(),
              const SizedBox(height: 16),
              _buildContentField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Tên nhà cung cấp',
        hintText: 'Nhập tên nhà cung cấp',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse_outlined),
      ),
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tên nhà cung cấp';
        }
        return null;
      },
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Mô tả',
        hintText: 'Nhập mô tả về nhà cung cấp (tùy chọn)',
        border: OutlineInputBorder(),
        // prefixIcon: Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      enabled: !_isLoading,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(_isEditMode ? 'Cập nhật' : 'Tạo mới'),
    );
  }
}
