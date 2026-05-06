part of '../enums.dart';

enum LineType {
  normal(1, 'Hàng hóa/dịch vụ bình thường'),
  promotional(2, 'Hàng khuyến mại'),
  discount(3, 'Chiết khấu thương mại'),
  note(4, 'Ghi chú');

  const LineType(this.value, this.label);

  final int value;
  final String label;

  static LineType? fromValue(int? value) {
    if (value == null) return null;
    for (final type in LineType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
