import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:flutter/material.dart';

/// Lắng nghe URL mở app (cold start + khi app đang chạy).
///
/// Hỗ trợ:
/// - `fcode://order/{orderId}`
/// - `https://fcode.vn/ahihi/shop-orders/{orderId}/edit`
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({required this.child, super.key});

  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.removeBadge();
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.handleDeepLink(initial.toString());
        });
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Deep link initial error: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => DeepLinkService.handleDeepLink(uri.toString()),
      onError: (Object e, StackTrace st) {
        debugPrintStack(stackTrace: st, label: 'Deep link stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}