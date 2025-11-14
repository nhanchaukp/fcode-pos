import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models/dto/customer_create_data.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:hux/hux.dart';

class CustomerCreateScreen extends StatefulWidget {
  const CustomerCreateScreen({super.key});

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
}

class _CustomerCreateScreenState extends State<CustomerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facebookController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      email: _emailController.text.trim(),
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
      final response = await CustomerService().create(data);
      if (!mounted) return;
      if (response.data != null) {
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error('Không thể tạo khách hàng.');
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
      appBar: AppBar(title: const Text('Thêm khách hàng mới')),
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v))
                  return 'Email không hợp lệ';
                if (v.length > 255) return 'Tối đa 255 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu (ít nhất 8 ký tự, không bắt buộc)',
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
            HuxButton(
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              child: const Text('Tạo khách hàng'),
            ),
          ],
        ),
      ),
    );
  }
}
