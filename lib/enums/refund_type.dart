part of '../enums.dart';

enum RefundType implements LabeledIconEnum {
  pending('Chờ xử lý', 'pending'),
  partial('Hoàn một phần', 'partial'),
  full('Hoàn toàn bộ', 'full'),
  item('Hoàn sản phẩm', 'item'),
  none('Không có', 'none');

  const RefundType(this.label, this.value);

  @override
  final String label;
  final String value;

  @override
  IconData get icon => switch (this) {
    RefundType.pending => Icons.hourglass_empty,
    RefundType.partial => Icons.pie_chart,
    RefundType.full => Icons.done_all,
    RefundType.item => Icons.shopping_bag,
    RefundType.none => Icons.block,
  };

  @override
  Color get color => switch (this) {
    RefundType.pending => AppColor.orange,
    RefundType.partial => AppColor.teal,
    RefundType.full => AppColor.indigo,
    RefundType.item => AppColor.purple,
    RefundType.none => AppColor.gray,
  };

  static RefundType? fromValue(String? value) {
    return _enumFromStringValue(
      RefundType.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
