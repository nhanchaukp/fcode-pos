part of '../enums.dart';

enum FinancialTransactionType implements LabeledIconEnum {
  orderPayment('order_payment', 'Thanh toán đơn hàng'),
  orderRenewal('order_renewal', 'Gia hạn đơn hàng'),
  refund('refund', 'Hoàn tiền'),
  accountRenewal('account_renewal', 'Gia hạn tài khoản'),
  fee('fee', 'Phí dịch vụ'),
  adjustment('adjustment', 'Điều chỉnh'),
  other('other', 'Khác');

  const FinancialTransactionType(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    FinancialTransactionType.orderPayment => Icons.payment,
    FinancialTransactionType.orderRenewal => Icons.autorenew,
    FinancialTransactionType.refund => Icons.undo,
    FinancialTransactionType.accountRenewal => Icons.refresh,
    FinancialTransactionType.fee => Icons.receipt,
    FinancialTransactionType.adjustment => Icons.tune,
    FinancialTransactionType.other => Icons.more_horiz,
  };

  @override
  Color get color => switch (this) {
    FinancialTransactionType.orderPayment => AppColor.green,
    FinancialTransactionType.orderRenewal => AppColor.blue,
    FinancialTransactionType.refund => AppColor.red,
    FinancialTransactionType.accountRenewal => AppColor.teal,
    FinancialTransactionType.fee => AppColor.orange,
    FinancialTransactionType.adjustment => AppColor.indigo,
    FinancialTransactionType.other => AppColor.gray,
  };

  static FinancialTransactionType? fromValue(String? value) {
    return _enumFromStringValue(
      FinancialTransactionType.values,
      value,
      (type) => type.value,
      caseInsensitive: true,
    );
  }

  static List<String> getAllValues() {
    return FinancialTransactionType.values
        .map((item) => item.value)
        .toList(growable: false);
  }

  static bool isValid(String value) {
    return fromValue(value) != null;
  }
}
