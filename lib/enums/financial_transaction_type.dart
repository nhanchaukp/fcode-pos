part of '../enums.dart';

enum FinancialTransactionType {
  orderPayment('order_payment', 'Thanh toán đơn hàng'),
  orderRenewal('order_renewal', 'Gia hạn đơn hàng'),
  refund('refund', 'Hoàn tiền'),
  accountRenewal('account_renewal', 'Gia hạn tài khoản'),
  fee('fee', 'Phí dịch vụ'),
  adjustment('adjustment', 'Điều chỉnh'),
  other('other', 'Khác');

  final String value;
  final String label;

  const FinancialTransactionType(this.value, this.label);

  static FinancialTransactionType? fromString(String? value) {
    if (value == null) return null;
    try {
      return FinancialTransactionType.values.firstWhere(
        (e) => e.value == value,
      );
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllValues() {
    return FinancialTransactionType.values.map((e) => e.value).toList();
  }

  static bool isValid(String value) {
    return FinancialTransactionType.values.any((e) => e.value == value);
  }
}
