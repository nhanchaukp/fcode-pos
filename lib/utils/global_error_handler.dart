import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../exceptions/api_exception.dart';

class GlobalErrorHandler {
  /// Initialize global error handlers
  static void initialize() {
    // Catch all errors from Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);

      if (kDebugMode) {
        // In debug mode, show error in console
        debugPrint('🔴 Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      } else {
        // In production, you can send to crash reporting service
        // e.g., Sentry, Firebase Crashlytics, etc.
        _reportErrorToService(details.exception, details.stack);
      }
    };

    // Catch errors outside of Flutter framework (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);

      if (kDebugMode) {
        debugPrint('🔴 Platform Error: $error');
        debugPrint('Stack trace: $stack');
      } else {
        _reportErrorToService(error, stack);
      }

      return true; // Handled
    };
  }

  /// Log error for debugging
  static void _logError(Object error, StackTrace? stack) {
    if (error is ApiException) {
      debugPrint('🔴 API Error [${error.statusCode}]: ${error.message}');
    } else {
      debugPrint('🔴 Error: $error');
    }
  }

  /// Report error to external service (Sentry, Firebase, etc.)
  static void _reportErrorToService(Object error, StackTrace? stack) {
    // TODO: Implement your error reporting service
    // Example:
    // Sentry.captureException(error, stackTrace: stack);
    // FirebaseCrashlytics.instance.recordError(error, stack);
  }

  /// Show user-friendly error dialog
  static void showErrorDialog(BuildContext context, Object error) {
    String title = 'Lỗi';
    String message = 'Đã xảy ra lỗi không xác định';

    if (error is ApiException) {
      title = 'Lỗi API';
      message = error.message;
    } else if (error is TimeoutException) {
      title = 'Hết thời gian chờ';
      message = 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.';
    } else if (error is FormatException) {
      title = 'Lỗi định dạng';
      message = 'Dữ liệu không hợp lệ';
    } else {
      message = error.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show user-friendly error snackbar
  static void showErrorSnackBar(BuildContext context, Object error) {
    String message = 'Đã xảy ra lỗi không xác định';

    if (error is ApiException) {
      message = error.message;
    } else if (error is TimeoutException) {
      message = 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.';
    } else if (error is FormatException) {
      message = 'Dữ liệu không hợp lệ';
    } else {
      message = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Handle error with automatic UI display
  static void handleError(BuildContext context, Object error,
      {bool useDialog = false}) {
    _logError(error, null);

    if (useDialog) {
      showErrorDialog(context, error);
    } else {
      showErrorSnackBar(context, error);
    }
  }
}
