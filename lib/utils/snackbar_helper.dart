import 'package:fcode_pos/appwrite.dart';
import 'package:flutter/material.dart';

enum _ToastrVariant { success, error, neutral }

/// Helper hiển thị SnackBar floating, đồng bộ theme M3 (surface container, không viền dày).
class Toastr {
  /// SnackBar thành công — dùng `primaryContainer` / `onPrimaryContainer`.
  static void success(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      variant: _ToastrVariant.success,
      icon: Icons.check_circle_outline,
      duration: duration,
      action: action,
      context: context,
    );
  }

  /// SnackBar lỗi — dùng `errorContainer` / `onErrorContainer`.
  static void error(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      variant: _ToastrVariant.error,
      icon: Icons.error_outline,
      duration: duration,
      action: action,
      context: context,
    );
  }

  /// SnackBar thông tin — dùng `surfaceContainerHigh` / `onSurface`.
  static void show(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IconData? icon,
  }) {
    _showSnackBar(
      message,
      variant: _ToastrVariant.neutral,
      icon: icon ?? Icons.info_outline,
      duration: duration,
      action: action,
      context: context,
    );
  }

  static void _showSnackBar(
    String message, {
    required _ToastrVariant variant,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
    BuildContext? context,
  }) {
    // Theme: cần context dưới MaterialApp (currentContext của messenger vẫn hợp lệ).
    final themeContext = context ?? rootScaffoldMessengerKey.currentContext;
    if (themeContext == null) return;

    final theme = Theme.of(themeContext);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (variant) {
      case _ToastrVariant.success:
        backgroundColor = const Color(0xFFDCF5E7);
        foregroundColor = const Color(0xFF1A5C35);
        break;
      case _ToastrVariant.error:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        break;
      case _ToastrVariant.neutral:
        backgroundColor = colorScheme.surfaceContainerHigh;
        foregroundColor = colorScheme.onSurface;
        break;
    }

    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.45);

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: duration,
      action: action,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );

    // Không dùng ScaffoldMessenger.of(rootScaffoldMessengerKey.currentContext):
    // context đó là của chính ScaffoldMessenger nên không có ancestor ScaffoldMessenger.
    final ScaffoldMessengerState? messenger = context != null
        ? (ScaffoldMessenger.maybeOf(context) ??
            rootScaffoldMessengerKey.currentState)
        : rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
