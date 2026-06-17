part of '../enums.dart';

enum FinancialTransactionStatus implements LabeledIconEnum {
  pending('pending', 'Chờ xử lý'),
  completed('completed', 'Hoàn thành'),
  failed('failed', 'Thất bại'),
  cancelled('cancelled', 'Đã hủy');

  const FinancialTransactionStatus(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    FinancialTransactionStatus.pending => Icons.hourglass_empty_rounded,
    FinancialTransactionStatus.completed => Icons.check_circle_outline_rounded,
    FinancialTransactionStatus.failed => Icons.error_outline_rounded,
    FinancialTransactionStatus.cancelled => Icons.cancel_outlined,
  };

  @override
  Color get color => switch (this) {
    FinancialTransactionStatus.pending => AppColor.orange,
    FinancialTransactionStatus.completed => AppColor.green,
    FinancialTransactionStatus.failed => AppColor.red,
    FinancialTransactionStatus.cancelled => AppColor.gray,
  };

  static FinancialTransactionStatus? fromValue(String? value) {
    return _enumFromStringValue(
      FinancialTransactionStatus.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}