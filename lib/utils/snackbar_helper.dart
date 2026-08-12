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

  static String _cleanErrorMessage(Object rawMessage) {
    String msg = rawMessage.toString();
    if (msg.contains('ApiException(')) {
      final regExp = RegExp(r'message:\s*([^)]+)');
      final match = regExp.firstMatch(msg);
      if (match != null && match.group(1) != null) {
        msg = match.group(1)!.trim();
      }
    }
    return msg;
  }

  static void error(
    Object message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) => _pkg.Toastr.error(
    _cleanErrorMessage(message),
    options: _pkg.ToastrOptions(duration: duration),
  );

  /// Hiển thị loading toast, sau đó tự động chuyển sang success hoặc error
  /// khi future hoàn thành.
  ///
  /// **Lưu ý quan trọng**: Vì package toastr_flutter hiện tại dùng `update()` để
  /// đổi type từ loading → success/error, animation icon (checkmark / x) có thể
  /// không chạy lại. Do đó chúng ta tự implement ở đây bằng cách:
  /// - Dùng `loading()` để lấy id
  /// - Dismiss loading toast
  /// - Gọi `success()` / `error()` thật sự (có icon đúng)
  static Future<T> promise<T>(
    Future<T> future, {
    String loading = 'Loading...',
    String success = 'Success!',
    String error = 'Something went wrong',
    String Function(T data)? successBuilder,
    String Function(Object error)? errorBuilder,
    Duration? successDuration,
    Duration? errorDuration,
  }) async {
    final id = _pkg.Toastr.loading(loading);

    try {
      final result = await future;

      // Đóng loading trước khi show success (tránh giữ icon loading)
      _pkg.Toastr.dismiss(id);

      final message = successBuilder != null ? successBuilder(result) : success;
      _pkg.Toastr.success(
        message,
        options: _pkg.ToastrOptions(
          duration: successDuration ?? const Duration(seconds: 2),
        ),
      );

      return result;
    } catch (e) {
      _pkg.Toastr.dismiss(id);

      final message = errorBuilder != null ? errorBuilder(e) : error;
      _pkg.Toastr.error(
        message,
        options: _pkg.ToastrOptions(
          duration: errorDuration ?? const Duration(seconds: 4),
          showCloseButton: true,
        ),
      );

      rethrow;
    }
  }

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
