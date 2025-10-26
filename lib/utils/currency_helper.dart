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

  /// Format số tiền dạng ngắn gọn: 1.2K, 3.4M, 1.2B...
  static String formatCompactCurrency(num amount) {
    final absAmount = amount.abs();
    String suffix = '';
    double value = amount.toDouble();

    if (absAmount >= 1e9) {
      value = amount / 1e9;
      suffix = 'B';
    } else if (absAmount >= 1e6) {
      value = amount / 1e6;
      suffix = 'M';
    } else if (absAmount >= 1e3) {
      value = amount / 1e3;
      suffix = 'K';
    } else {
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return formatter.format(amount);
    }

    String formatted = value.toStringAsFixed(value.abs() >= 10 ? 1 : 2);
    formatted = formatted.replaceFirst(RegExp(r'\.?0+$'), '');
    final sign = amount < 0 ? '-' : '';
    return '$sign$formatted$suffix';
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
