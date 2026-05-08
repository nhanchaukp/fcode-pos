part of '../enums.dart';

enum CouponType {
  subtraction('subtraction', 'Giảm trừ', Colors.blue),
  percentage('percentage', 'Phần trăm', Colors.orange),
  fixed('fixed', 'Giá cố định', Colors.green);

  final String value;
  final String label;
  final Color color;

  const CouponType(this.value, this.label, this.color);

  static CouponType? fromString(String? value) {
    if (value == null) return null;
    try {
      return CouponType.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}
