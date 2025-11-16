part of '../models.dart';

/// Item in an expiring order
class ExpiringOrderItem {
  final String productName;
  final int quantity;
  final DateTime? expiredAt;
  final int daysRemaining;

  ExpiringOrderItem({
    required this.productName,
    required this.quantity,
    this.expiredAt,
    required this.daysRemaining,
  });

  factory ExpiringOrderItem.fromJson(Map<String, dynamic> map) {
    return ExpiringOrderItem(
      productName: map['product_name']?.toString() ?? '',
      quantity: asInt(map['quantity']),
      expiredAt: map['expired_at'] != null
          ? DateTime.tryParse(map['expired_at'].toString())
          : null,
      daysRemaining: asInt(map['days_remaining']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'expired_at': expiredAt?.toIso8601String(),
      'days_remaining': daysRemaining,
    };
  }
}

/// An order that is expiring soon
class ExpiringOrder {
  final int orderId;
  final String userName;
  final String userEmail;
  final int itemsCount;
  final List<ExpiringOrderItem> items;

  ExpiringOrder({
    required this.orderId,
    required this.userName,
    required this.userEmail,
    required this.itemsCount,
    required this.items,
  });

  factory ExpiringOrder.fromJson(Map<String, dynamic> map) {
    return ExpiringOrder(
      orderId: asInt(map['order_id']),
      userName: map['user_name']?.toString() ?? '',
      userEmail: map['user_email']?.toString() ?? '',
      itemsCount: asInt(map['items_count']),
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (e) => ExpiringOrderItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'user_name': userName,
      'user_email': userEmail,
      'items_count': itemsCount,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}

/// Summary of orders expiring soon
class OrdersExpiringSoon {
  final int count;
  final int itemsCount;
  final int totalValue;
  final List<ExpiringOrder> orders;

  OrdersExpiringSoon({
    required this.count,
    required this.itemsCount,
    required this.totalValue,
    required this.orders,
  });

  factory OrdersExpiringSoon.fromJson(Map<String, dynamic> map) {
    return OrdersExpiringSoon(
      count: asInt(map['count']),
      itemsCount: asInt(map['items_count']),
      totalValue: asInt(map['total_value']),
      orders:
          (map['orders'] as List<dynamic>?)
              ?.map((e) => ExpiringOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'items_count': itemsCount,
      'total_value': totalValue,
      'orders': orders.map((e) => e.toMap()).toList(),
    };
  }
}

/// Order Statistics
class OrderStats {
  /// Total money amount.
  final int totalMoney;

  /// Revenue amount.
  final int revenue;

  /// Count of orders with successful payment.
  final int paymentSuccessOrderCount;

  /// Count of new orders.
  final int newOrderCount;

  /// Count of completed orders.
  final int completeOrderCount;

  /// Count of refunded orders.
  final int refundOrderCount;

  /// Total count of all orders.
  final int totalOrdersCount;

  /// Orders expiring soon details.
  final OrdersExpiringSoon? ordersExpiringSoon;

  OrderStats({
    required this.totalMoney,
    required this.revenue,
    required this.paymentSuccessOrderCount,
    required this.newOrderCount,
    required this.completeOrderCount,
    required this.refundOrderCount,
    required this.totalOrdersCount,
    this.ordersExpiringSoon,
  });

  factory OrderStats.fromJson(Map<String, dynamic> map) {
    return OrderStats(
      totalMoney: asInt(map['total_money']),
      revenue: asInt(map['revenue']),
      paymentSuccessOrderCount: asInt(map['payment_success_order_count']),
      newOrderCount: asInt(map['new_order_count']),
      completeOrderCount: asInt(map['complete_order_count']),
      refundOrderCount: asInt(map['refund_order_count']),
      totalOrdersCount: asInt(map['total_orders_count']),
      ordersExpiringSoon: map['orders_expiring_soon'] != null
          ? OrdersExpiringSoon.fromJson(
              map['orders_expiring_soon'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_money': totalMoney,
      'revenue': revenue,
      'payment_success_order_count': paymentSuccessOrderCount,
      'new_order_count': newOrderCount,
      'complete_order_count': completeOrderCount,
      'refund_order_count': refundOrderCount,
      'total_orders_count': totalOrdersCount,
      'orders_expiring_soon': ordersExpiringSoon?.toMap(),
    };
  }
}
