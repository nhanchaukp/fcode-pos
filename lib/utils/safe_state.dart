import 'package:flutter/widgets.dart';

/// A safe wrapper around [setState] that only updates
/// when the widget is still mounted in the widget tree.
///
/// ✅ Prevents memory leaks and "setState() called after dispose()" errors.
/// ✅ Keeps code clean (no need to check `if (!mounted) return;` manually).
///
/// Usage:
/// ```dart
/// safeSetState(() => _loading = false);
/// ```
extension SafeState on State {
  /// Calls [setState] only if the [State] is still mounted.
  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}
