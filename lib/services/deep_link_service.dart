import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:flutter/material.dart';

/// Xử lý URL mở app và điều hướng tới màn hình tương ứng.
///
/// Định dạng hỗ trợ:
/// - `fcode://order/{orderId}`
/// - `https://fcode.vn/ahihi/shop-orders/{orderId}/edit`
class DeepLinkService {
  static String? _pendingOrderId;

  static void handleDeepLink(String? deepLink) {
    if (deepLink == null || deepLink.isEmpty) return;

    debugPrint('🔗 Deep link: $deepLink');

    try {
      final orderId = _parseOrderId(deepLink);
      if (orderId != null) {
        _navigateToOrderDetail(orderId);
      } else {
        debugPrint('⚠️ Không nhận dạng được deep link: $deepLink');
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: '❌ Deep link error: $e');
    }
  }

  /// Gọi sau khi app đã đăng nhập và navigator sẵn sàng.
  static void processPendingNavigation() {
    final orderId = _pendingOrderId;
    if (orderId == null) return;
    _pendingOrderId = null;
    _navigateToOrderDetail(orderId);
  }

  static String? _parseOrderId(String deepLink) {
    final uri = Uri.parse(deepLink);
    final segments = uri.pathSegments;

    if (uri.scheme == 'fcode' && uri.host == 'order') {
      if (segments.isNotEmpty && segments.first.isNotEmpty) {
        return segments.first;
      }
      return null;
    }

    if (uri.scheme == 'https' && uri.host == 'fcode.vn') {
      final index = segments.indexOf('shop-orders');
      if (index >= 0 && index + 1 < segments.length) {
        final orderId = segments[index + 1];
        if (orderId.isNotEmpty) return orderId;
      }
    }

    return null;
  }

  static void _navigateToOrderDetail(String orderId) {
    final state = navigatorKey.currentState;
    if (state == null) {
      _pendingOrderId = orderId;
      debugPrint('📋 Queued order deep link: $orderId');
      return;
    }

    debugPrint('📋 Open order: $orderId');
    state.push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();