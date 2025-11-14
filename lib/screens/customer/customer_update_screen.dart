import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models/dto/customer_create_data.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:fcode_pos/models.dart';

class CustomerUpdateScreen extends StatefulWidget {
  final User user;
  const CustomerUpdateScreen({super.key, required this.user});

  @override
  State<CustomerUpdateScreen> createState() => _CustomerUpdateScreenState();
}

class _CustomerUpdateScreenState extends State<CustomerUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _facebookController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _passwordController = TextEditingController();
    _facebookController = TextEditingController(
      text: widget.user.facebook ?? '',
    );
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _facebookController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    final data = CustomerCreateData(
      name: _nameController.text.trim(),
      email: widget.user.email, // Email không cho update
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      facebook: _facebookController.text.trim().isEmpty
          ? null
          : _facebookController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );
    try {
      final response = await CustomerService().update(widget.user.id, data);
      if (!mounted) return;
      if (response.data != null) {
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error('Không thể cập nhật khách hàng.');
      }
    } catch (e) {
      Toastr.error(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật khách hàng')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên khách hàng'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập tên';
                if (v.length > 255) return 'Tối đa 255 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (ít nhất 8 ký tự, không bắt buộc)',
              ),
              obscureText: true,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 8)
                  return 'Tối thiểu 8 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook (không bắt buộc)',
              ),
              validator: (v) {
                if (v != null && v.length > 255) return 'Tối đa 255 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại (không bắt buộc)',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.length > 20) return 'Tối đa 20 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cập nhật khách hàng'),
            ),
          ],
        ),
      ),
    );
  }
}
