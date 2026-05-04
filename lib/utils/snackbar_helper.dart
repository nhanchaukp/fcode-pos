import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/config/theme_colors.dart';
import 'package:flutter/material.dart';

enum _ToastrVariant { success, info, warning, error }

/// SnackBar floating dùng màu semantic từ [AppColors] ThemeExtension của palette.
class Toastr {
  static void success(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) =>
      _show(message,
          variant: _ToastrVariant.success,
          icon: Icons.check_circle_outline,
          duration: duration,
          action: action,
          context: context);

  static void info(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) =>
      _show(message,
          variant: _ToastrVariant.info,
          icon: Icons.info_outline,
          duration: duration,
          action: action,
          context: context);

  static void warning(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) =>
      _show(message,
          variant: _ToastrVariant.warning,
          icon: Icons.warning_amber_outlined,
          duration: duration,
          action: action,
          context: context);

  static void error(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) =>
      _show(message,
          variant: _ToastrVariant.error,
          icon: Icons.error_outline,
          duration: duration,
          action: action,
          context: context);

  /// Alias cho [info] — tương thích code cũ.
  static void show(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IconData? icon,
  }) =>
      _show(message,
          variant: _ToastrVariant.info,
          icon: icon ?? Icons.info_outline,
          duration: duration,
          action: action,
          context: context);

  static void _show(
    String message, {
    required _ToastrVariant variant,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
    BuildContext? context,
  }) {
    final themeContext = context ?? rootScaffoldMessengerKey.currentContext;
    if (themeContext == null) return;

    final theme = Theme.of(themeContext);
    final appColors = theme.extension<AppColors>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Lấy màu từ AppColors extension; fallback về colorScheme nếu chưa đăng ký.
    final Color bg;
    final Color fg;
    switch (variant) {
      case _ToastrVariant.success:
        bg = appColors?.success ?? const Color(0xFF16a34a);
        fg = appColors?.onSuccess ?? Colors.white;
      case _ToastrVariant.info:
        bg = appColors?.info ?? colorScheme.secondaryContainer;
        fg = appColors?.onInfo ?? colorScheme.onSecondaryContainer;
      case _ToastrVariant.warning:
        bg = appColors?.warning ?? const Color(0xFFf59e0b);
        fg = appColors?.onWarning ?? Colors.black;
      case _ToastrVariant.error:
        bg = appColors?.danger ?? colorScheme.errorContainer;
        fg = appColors?.onDanger ?? colorScheme.onErrorContainer;
    }

    final snackBar = SnackBar(
      elevation: 2,
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: duration,
      action: action,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );

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
