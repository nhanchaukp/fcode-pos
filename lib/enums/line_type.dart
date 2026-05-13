part of '../enums.dart';

enum LineType implements LabeledIconEnum {
  normal(1, 'Hàng hóa/dịch vụ bình thường'),
  promotional(2, 'Hàng khuyến mại'),
  discount(3, 'Chiết khấu thương mại'),
  note(4, 'Ghi chú');

  const LineType(this.value, this.label);

  final int value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    LineType.normal => Icons.inventory_2,
    LineType.promotional => Icons.local_offer,
    LineType.discount => Icons.sell,
    LineType.note => Icons.description,
  };

  @override
  Color get color => switch (this) {
    LineType.normal => AppColor.blue,
    LineType.promotional => AppColor.green,
    LineType.discount => AppColor.orange,
    LineType.note => AppColor.gray,
  };

  static LineType? fromValue(int? value) {
    return _enumFromValue(LineType.values, value, (item) => item.value);
  }
}
