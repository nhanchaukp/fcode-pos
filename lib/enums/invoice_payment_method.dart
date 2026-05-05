part of '../enums.dart';

/// Giá trị gửi API phải khớp backend `PaymentMethod` (TM, CK, TM/CK, KHAC).
enum InvoicePaymentMethod {
  tm('TM', 'Tiền mặt (Cash)'),
  ck('CK', 'Chuyển khoản (Bank transfer)'),
  tmAndCk('TM/CK', 'Tiền mặt và chuyển khoản (Cash and bank transfer)'),
  khac('KHAC', 'Khác (Other)');

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
