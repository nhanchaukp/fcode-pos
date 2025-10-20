import 'package:flutter/material.dart';

class AccountFormInput extends StatefulWidget {
  final Map<String, dynamic>? initialAccount;
  final Function(Map<String, dynamic>?) onAccountChanged;

  const AccountFormInput({
    this.initialAccount,
    required this.onAccountChanged,
    super.key,
  });

  @override
  State<AccountFormInput> createState() => _AccountFormInputState();
}

class _AccountFormInputState extends State<AccountFormInput> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    String username = '';
    String password = '';

    if (widget.initialAccount != null) {
      final account = widget.initialAccount!;

      // If account is an array, take the first item
      if (account.containsKey('data') && account['data'] is List) {
        final List data = account['data'] as List;
        if (data.isNotEmpty && data[0] is Map) {
          final firstItem = data[0] as Map<String, dynamic>;
          // Get first key-value pair as username-password
          if (firstItem.isNotEmpty) {
            final entry = firstItem.entries.first;
            username = entry.key;
            password = entry.value?.toString() ?? '';
          }
        }
      } else {
        // If account is a simple object, get first key-value pair
        if (account.isNotEmpty) {
          final entry = account.entries.first;
          username = entry.key;
          password = entry.value?.toString() ?? '';
        }
      }
    }

    _usernameController = TextEditingController(text: username);
    _passwordController = TextEditingController(text: password);

    // Add listeners to notify parent of changes
    _usernameController.addListener(_notifyChanges);
    _passwordController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_notifyChanges);
    _passwordController.removeListener(_notifyChanges);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty && password.isEmpty) {
      widget.onAccountChanged(null);
    } else {
      widget.onAccountChanged({
        username: password,
      });
    }
  }

  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Nhập username',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Nhập password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          obscureText: false, // Set to true if you want to hide password
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _clearFields,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Xóa'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
