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
  bool _obscurePassword = false;

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
          final Map firstItem = data[0] as Map;
          // Get first key-value pair as username-password
          if (firstItem.isNotEmpty) {
            final entry = firstItem.entries.first;
            username = entry.key?.toString() ?? '';
            password = entry.value?.toString() ?? '';
          }
        }
      } else {
        // If account is a simple object, get first key-value pair
        if (account.isNotEmpty) {
          final entry = account.entries.first;
          username = entry.key.toString();
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
      widget.onAccountChanged({username: password});
    }
  }

  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
  }

  bool get _hasValue =>
      _usernameController.text.isNotEmpty ||
      _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final inputBorder = theme.inputDecorationTheme.border;
    final BorderRadiusGeometry borderRadius = inputBorder is OutlineInputBorder
        ? inputBorder.borderRadius
        : (theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
            : const BorderRadius.all(Radius.circular(10)));
    final BorderSide side = inputBorder is OutlineInputBorder
        ? inputBorder.borderSide
        : (theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape as RoundedRectangleBorder).side
            : BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Thông tin tài khoản',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_hasValue)
              TextButton.icon(
                onPressed: _clearFields,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Xóa'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: side,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Tài khoản (Username / Email)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              Divider(
                height: 1,
                thickness: 0.3,
                color: side.color,
                indent: 44,
                endIndent: 12,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Mật khẩu (Password)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    tooltip:
                        _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
