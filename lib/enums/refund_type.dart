part of '../enums.dart';

enum RefundType {
  pending('Chờ xử lý', 'pending'),
  partial('Hoàn một phần', 'partial'),
  full('Hoàn toàn bộ', 'full'),
  item('Hoàn sản phẩm', 'item'),
  none('Không có', 'none');

  const RefundType(this.label, this.value);

  final String label;
  final String value;

  static RefundType? fromValue(String? value) {
    if (value == null) return null;
    try {
      return RefundType.values.firstWhere((type) => type.value == value);
    } catch (e) {
      return null;
    }
  }
}
