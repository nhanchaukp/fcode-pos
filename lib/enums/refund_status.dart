part of '../enums.dart';

enum RefundStatus implements LabeledIconEnum {
  pending('Chờ xử lý', 'pending'),
  approved('Đã duyệt', 'approved'),
  rejected('Từ chối', 'rejected'),
  completed('Hoàn thành', 'completed');

  const RefundStatus(this.label, this.value);

  @override
  final String label;
  final String value;

  @override
  IconData get icon => switch (this) {
    RefundStatus.pending => Icons.hourglass_empty,
    RefundStatus.approved => Icons.check_circle,
    RefundStatus.rejected => Icons.cancel,
    RefundStatus.completed => Icons.done,
  };

  @override
  Color get color => switch (this) {
    RefundStatus.pending => AppColor.orange,
    RefundStatus.approved => AppColor.blue,
    RefundStatus.rejected => AppColor.red,
    RefundStatus.completed => AppColor.green,
  };

  static RefundStatus? fromValue(String? value) {
    return _enumFromStringValue(
      RefundStatus.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
