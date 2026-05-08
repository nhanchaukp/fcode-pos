import 'package:flutter/material.dart';
import 'package:toastr_flutter/toastr.dart' show ToastrHelper;

/// Wrapper quanh [ToastrHelper] từ package `toastr_flutter`.
/// Giữ nguyên interface cũ để không cần sửa code gọi ở nơi khác.
/// Cấu hình global (position, animation) được đặt trong [AppInitializer._setupToastr].
/// [BuildContext] và [SnackBarAction] được giữ lại trong signature
/// nhưng bị bỏ qua vì `toastr_flutter` không cần context.
class Toastr {
  Toastr._();

  static void success(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) =>
      ToastrHelper.success(message, duration: duration);

  static void info(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) =>
      ToastrHelper.info(message, duration: duration);

  static void warning(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) =>
      ToastrHelper.warning(message, duration: duration);

  static void error(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) =>
      ToastrHelper.error(message, duration: duration);

  static Future<T> promise<T>(
    Future<T> future, {
    String loading = 'Đang xử lý...',
    String success = 'Thành công!',
    String error = 'Đã xảy ra lỗi',
    String Function(T data)? successBuilder,
    String Function(Object error)? errorBuilder,
    Duration? successDuration,
    Duration? errorDuration,
  }) =>
      ToastrHelper.promise<T>(
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
  }) =>
      ToastrHelper.info(message, duration: duration);
}
