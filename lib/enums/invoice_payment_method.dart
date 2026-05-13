part of '../enums.dart';

/// Giá trị gửi API phải khớp backend `PaymentMethod` (TM, CK, TM/CK, KHAC).
enum InvoicePaymentMethod implements LabeledIconEnum {
  tm('TM', 'Tiền mặt (TM)'),
  ck('CK', 'Chuyển khoản (CK)'),
  tmAndCk('TM/CK', 'Tiền mặt và chuyển khoản (TM/CK)'),
  khac('KHAC', 'Khác (KHAC)');

  const InvoicePaymentMethod(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    InvoicePaymentMethod.tm => Icons.attach_money,
    InvoicePaymentMethod.ck => Icons.account_balance,
    InvoicePaymentMethod.tmAndCk => Icons.swap_horiz,
    InvoicePaymentMethod.khac => Icons.more_horiz,
  };

  @override
  Color get color => switch (this) {
    InvoicePaymentMethod.tm => AppColor.green,
    InvoicePaymentMethod.ck => AppColor.blue,
    InvoicePaymentMethod.tmAndCk => AppColor.purple,
    InvoicePaymentMethod.khac => AppColor.gray,
  };

  static InvoicePaymentMethod? fromValue(String? value) {
    return _enumFromStringValue(
      InvoicePaymentMethod.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
