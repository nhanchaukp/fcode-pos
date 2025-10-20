import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Format số tiền theo định dạng Việt Nam
  static String formatCurrency(int amount, {String symbol = '₫'}) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(amount)} $symbol';
  }

  /// Format số tiền với decimal
  static String formatCurrencyWithDecimal(int amount,
      {String symbol = '₫', int decimalDigits = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}', 'vi_VN');
    return '${formatter.format(amount)} $symbol';
  }

  /// Parse string sang int
  static int parseCurrency(String value) {
    // Remove all non-numeric characters except dot and comma
    final cleaned = value.replaceAll(RegExp(r'[^\d.,]'), '');
    // Replace comma with dot for parsing
    final normalized = cleaned.replaceAll(',', '.');
    return int.tryParse(normalized.split('.')[0]) ?? 0;
  }
}
