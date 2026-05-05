part of '../enums.dart';

/// Giá trị gửi API phải khớp backend `Currency`.
enum InvoiceCurrency {
  vnd('VND', 'Việt Nam Đồng'),
  usd('USD', 'Đô la Mỹ'),
  cad('CAD', 'Đô la Canada');

  const InvoiceCurrency(this.value, this.label);

  final String value;
  final String label;

  static InvoiceCurrency? fromValue(String? v) {
    if (v == null || v.isEmpty) return null;
    final s = v.trim().toUpperCase();
    try {
      return InvoiceCurrency.values.firstWhere((e) => e.value == s);
    } catch (_) {
      return null;
    }
  }
}
