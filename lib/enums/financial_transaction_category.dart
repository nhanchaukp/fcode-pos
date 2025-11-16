part of '../enums.dart';

enum FinancialTransactionCategory {
  revenue('revenue', 'Doanh thu'),
  expense('expense', 'Chi phí'),
  refund('refund', 'Hoàn tiền'),
  cost('cost', 'Giá vốn'),
  profit('profit', 'Lợi nhuận'),
  fee('fee', 'Phí');

  final String value;
  final String label;

  const FinancialTransactionCategory(this.value, this.label);

  static FinancialTransactionCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return FinancialTransactionCategory.values.firstWhere(
        (e) => e.value == value,
      );
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllValues() {
    return FinancialTransactionCategory.values.map((e) => e.value).toList();
  }

  static bool isValid(String value) {
    return FinancialTransactionCategory.values.any((e) => e.value == value);
  }
}
