import 'package:fcode_pos/appwrite.dart';
import 'package:flutter/material.dart';

/// Helper class để hiển thị SnackBar ở bất kỳ đâu trong app
class SnackBarHelper {
  /// Hiển thị SnackBar thành công (màu xanh lá)
  static void success(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar lỗi (màu đỏ)
  static void error(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar mặc định (màu xám đen)
  static void show(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IconData? icon,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.grey[800]!,
      icon: icon ?? Icons.info,
      duration: duration,
      action: action,
    );
  }

  /// Hàm private để hiển thị SnackBar với các tùy chọn
  static void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );

    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
