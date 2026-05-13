part of '../models.dart';

class Coupon implements Model {
  final int id;
  final String code;
  final String type;
  final String value;
  final bool isEnabled;
  final int? quantity;
  final int? limit;
  final int? maxDiscount;
  final DateTime? expiresAt;
  final int usageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.isEnabled,
    this.quantity,
    this.limit,
    this.maxDiscount,
    this.expiresAt,
    this.usageCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> map) {
    return Coupon(
      id: asInt(map['id']),
      code: map['code']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      value: map['value']?.toString() ?? '0',
      isEnabled: map['is_enabled'] == true || map['is_enabled'] == 1,
      quantity: asIntOrNull(map['quantity']),
      limit: asIntOrNull(map['limit']),
      maxDiscount: asIntOrNull(map['max_discount']),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())?.toLocal()
          : null,
      usageCount: asInt(map['usage_count']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal()
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'is_enabled': isEnabled,
      'quantity': quantity,
      'limit': limit,
      'max_discount': maxDiscount,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  enums.CouponType? get couponType => enums.CouponType.fromValue(type);

  String get discountText {
    final couponType = this.couponType;
    if (couponType == null) return value;
    switch (couponType) {
      case enums.CouponType.percentage:
        return '$value%';
      case enums.CouponType.subtraction:
      case enums.CouponType.fixed:
        return value;
    }
  }
}
