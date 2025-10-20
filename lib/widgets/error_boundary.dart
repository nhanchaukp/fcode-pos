import 'package:flutter/material.dart';
import '../utils/global_error_handler.dart';

/// A widget that catches and handles errors from its child widgets
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;
  final bool showErrorInUI;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.showErrorInUI = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Reset error when widget is initialized
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.showErrorInUI) {
      // Show error UI
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }

      return _buildDefaultErrorUI();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorUI() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension method to easily wrap widgets with error handling
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget Function(Object error)? errorBuilder,
    bool showErrorInUI = true,
  }) {
    return ErrorBoundary(
      errorBuilder: errorBuilder,
      showErrorInUI: showErrorInUI,
      child: this,
    );
  }
}

/// A mixin to handle async errors in widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Execute async operation with error handling
  Future<R?> handleAsync<R>(
    Future<R> Function() operation, {
    bool showDialog = false,
    void Function(R)? onSuccess,
    void Function(Object)? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return result;
    } catch (e) {
      GlobalErrorHandler.handleError(context, e, useDialog: showDialog);
      onError?.call(e);
      return null;
    }
  }

  /// Execute async operation without showing UI error
  Future<R?> handleAsyncSilently<R>(
    Future<R> Function() operation, {
    void Function(R)? onSuccess,
    void Function(Object)? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return result;
    } catch (e) {
      debugPrint('Silent error: $e');
      onError?.call(e);
      return null;
    }
  }
}
