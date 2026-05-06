part of '../enums.dart';

/// Giá trị gửi API phải khớp backend `PaymentMethod` (TM, CK, TM/CK, KHAC).
enum InvoicePaymentMethod {
  tm('TM', 'Tiền mặt (TM)'),
  ck('CK', 'Chuyển khoản (CK)'),
  tmAndCk('TM/CK', 'Tiền mặt và chuyển khoản (TM/CK)'),
  khac('KHAC', 'Khác (KHAC)');

  const InvoicePaymentMethod(this.value, this.label);

  final String value;
  final String label;

  static InvoicePaymentMethod? fromValue(String? v) {
    if (v == null || v.isEmpty) return null;
    final s = v.trim();
    final normalized = s.toUpperCase();
    try {
      return InvoicePaymentMethod.values.firstWhere(
        (e) => e.value.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}
