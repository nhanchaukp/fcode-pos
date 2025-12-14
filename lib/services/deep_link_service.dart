import 'package:flutter/material.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';

class DeepLinkService {
  /// Handle deep link URLs
  /// Examples:
  /// - fcode://order/1396 -> mở đơn 1396
  /// - https://fcode.vn/ahihi/shop-orders/1369/edit -> mở đơn 1369
  static Future<void> handleDeepLink(String? deepLink) async {
    if (deepLink == null || deepLink.isEmpty) return;

    debugPrint('🔗 Handling deep link: $deepLink');

    try {
      final uri = Uri.parse(deepLink);
      final pathSegments = uri.pathSegments;

      // Match pattern: fcode://order/{orderId}
      if (uri.scheme == 'fcode' && uri.host == 'order') {
        if (pathSegments.isNotEmpty && pathSegments[0].isNotEmpty) {
          final orderId = pathSegments[0];
          _navigateToOrderDetail(orderId);
          return;
        }
      }

      // Match pattern: https://fcode.vn/ahihi/shop-orders/{orderId}/edit
      if (uri.scheme == 'https' &&
          uri.host == 'fcode.vn' &&
          pathSegments.length >= 4 &&
          pathSegments[0] == 'ahihi' &&
          pathSegments[1] == 'shop-orders' &&
          pathSegments[3] == 'edit') {
        final orderId = pathSegments[2];
        _navigateToOrderDetail(orderId);
        return;
      }

      debugPrint('⚠️ Unknown deep link pattern: $deepLink');
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: '❌ Error handling deep link: $e');
    }
  }

  static void _navigateToOrderDetail(String orderId) {
    debugPrint('📋 Navigating to order: $orderId');
    final navigatorKey = _getNavigatorKey();
    if (navigatorKey.currentContext != null) {
      navigatorKey.currentState?.pushNamed('/order-detail', arguments: orderId);
    }
  }

  static GlobalKey<NavigatorState> _getNavigatorKey() {
    return navigatorKey;
  }
}

// Global navigator key for deep linking
final navigatorKey = GlobalKey<NavigatorState>();
