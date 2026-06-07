import 'package:flutter/material.dart';
import 'package:toastr_flutter/toastr.dart' as _pkg;

/// Wrapper giữ nguyên interface cũ (context, SnackBarAction) để không cần
/// sửa code gọi ở nơi khác. Nội bộ delegate sang [_pkg.Toastr] (toastr_flutter).
///
/// Import alias `_pkg` tránh xung đột tên với `class Toastr` trong package.
class Toastr {
  Toastr._();

  static void success(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) => _pkg.Toastr.success(
    message,
    options: _pkg.ToastrOptions(duration: duration),
  );

  static void info(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) => _pkg.Toastr.info(
    message,
    options: _pkg.ToastrOptions(duration: duration),
  );

  static void warning(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) => _pkg.Toastr.warning(
    message,
    options: _pkg.ToastrOptions(duration: duration),
  );

  static void error(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) => _pkg.Toastr.error(
    message,
    options: _pkg.ToastrOptions(duration: duration),
  );

  static Future<T> promise<T>(
    Future<T> future, {
    String loading = 'Đang xử lý...',
    String success = 'Thành công!',
    String error = 'Đã xảy ra lỗi',
    String Function(T data)? successBuilder,
    String Function(Object error)? errorBuilder,
    Duration? successDuration,
    Duration? errorDuration,
  }) => _pkg.Toastr.promise<T>(
    future,
    loading: loading,
    success: success,
    error: error,
    successBuilder: successBuilder,
    errorBuilder: errorBuilder,
    successDuration: successDuration,
    errorDuration: errorDuration,
  );

  /// Alias cho [info] — tương thích code cũ.
  static void show(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IconData? icon,
  }) => _pkg.Toastr.info(
    message,
    options: _pkg.ToastrOptions(duration: duration),
  );

  static String loading(String message) => _pkg.Toastr.loading(message);

  static void dismiss([String? id]) => _pkg.Toastr.dismiss(id);
}
