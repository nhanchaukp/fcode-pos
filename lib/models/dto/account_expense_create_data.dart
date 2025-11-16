import 'package:fcode_pos/enums.dart' as enums;

class AccountExpenseCreateData {
  final int accountId;
  final enums.FinancialTransactionType type;
  final enums.FinancialTransactionCategory category;
  final int amount;
  final String description;
  final DateTime expenseDate;

  AccountExpenseCreateData({
    required this.accountId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
  });

  factory AccountExpenseCreateData.fromJson(Map<String, dynamic> json) {
    return AccountExpenseCreateData(
      accountId: json['account_id'] as int,
      type: enums.FinancialTransactionType.fromString(json['type'] as String)!,
      category: enums.FinancialTransactionCategory.fromString(
        json['category'] as String,
      )!,
      amount: json['amount'] as int,
      description: json['description'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'type': type.value,
      'category': category.value,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AccountExpenseCreateData(account_id: '
        '$accountId, type: ${type.value}, category: ${category.value}, '
        'amount: $amount, description: $description, '
        'expense_date: ${expenseDate.toUtc().toIso8601String()})';
  }
}
