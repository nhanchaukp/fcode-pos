part of '../models.dart';

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

  OrderStats({
    required this.totalMoney,
    required this.revenue,
    required this.paymentSuccessOrderCount,
    required this.newOrderCount,
    required this.completeOrderCount,
    required this.refundOrderCount,
    required this.totalOrdersCount,
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
    };
  }
}
