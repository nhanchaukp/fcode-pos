part of '../enums.dart';

enum FinancialTransactionCategory implements LabeledIconEnum {
  revenue('revenue', 'Doanh thu'),
  expense('expense', 'Chi phí'),
  refund('refund', 'Hoàn tiền'),
  cost('cost', 'Giá vốn'),
  profit('profit', 'Lợi nhuận'),
  fee('fee', 'Phí');

  const FinancialTransactionCategory(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    FinancialTransactionCategory.revenue => Icons.trending_up,
    FinancialTransactionCategory.expense => Icons.trending_down,
    FinancialTransactionCategory.refund => Icons.undo,
    FinancialTransactionCategory.cost => Icons.inventory,
    FinancialTransactionCategory.profit => Icons.show_chart,
    FinancialTransactionCategory.fee => Icons.receipt,
  };

  @override
  Color get color => switch (this) {
    FinancialTransactionCategory.revenue => AppColor.green,
    FinancialTransactionCategory.expense => AppColor.orange,
    FinancialTransactionCategory.refund => AppColor.red,
    FinancialTransactionCategory.cost => AppColor.indigo,
    FinancialTransactionCategory.profit => AppColor.teal,
    FinancialTransactionCategory.fee => AppColor.purple,
  };

  static FinancialTransactionCategory? fromValue(String? value) {
    return _enumFromStringValue(
      FinancialTransactionCategory.values,
      value,
      (type) => type.value,
      caseInsensitive: true,
    );
  }

  static List<String> getAllValues() {
    return FinancialTransactionCategory.values
        .map((item) => item.value)
        .toList(growable: false);
  }

  static bool isValid(String value) {
    return fromValue(value) != null;
  }
}
