part of '../enums.dart';

enum CouponType implements LabeledIconEnum {
  subtraction('subtraction', 'Giảm trừ', AppColor.blue),
  percentage('percentage', 'Phần trăm', AppColor.orange),
  fixed('fixed', 'Giá cố định', AppColor.green);

  const CouponType(this.value, this.label, this.color);

  final String value;

  @override
  final String label;

  @override
  final Color color;

  @override
  IconData get icon => switch (this) {
    CouponType.subtraction => Icons.remove_circle,
    CouponType.percentage => Icons.percent,
    CouponType.fixed => Icons.attach_money,
  };

  static CouponType? fromValue(String? value) {
    return _enumFromStringValue(
      CouponType.values,
      value,
      (type) => type.value,
      caseInsensitive: true,
    );
  }
}
