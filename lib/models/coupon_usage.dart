part of '../models.dart';

class CouponUsage {
  final int orderId;
  final int orderTotal;
  final String orderStatus;
  final DateTime? redeemedAt;
  final User? user;

  CouponUsage({
    required this.orderId,
    required this.orderTotal,
    required this.orderStatus,
    this.redeemedAt,
    this.user,
  });

  factory CouponUsage.fromJson(Map<String, dynamic> map) {
    return CouponUsage(
      orderId: asInt(map['order_id']),
      orderTotal: asInt(map['order_total']),
      orderStatus: map['order_status']?.toString() ?? '',
      redeemedAt: map['redeemed_at'] != null
          ? DateTime.tryParse(map['redeemed_at'].toString())?.toLocal()
          : null,
      user: map['user'] != null
          ? User.fromJson(ensureMap(map['user']))
          : null,
    );
  }
}
