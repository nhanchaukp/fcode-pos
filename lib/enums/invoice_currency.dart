part of '../enums.dart';

/// Giá trị gửi API phải khớp backend `Currency`.
enum InvoiceCurrency implements LabeledIconEnum {
  vnd('VND', 'Việt Nam Đồng'),
  usd('USD', 'Đô la Mỹ'),
  cad('CAD', 'Đô la Canada');

  const InvoiceCurrency(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    InvoiceCurrency.vnd => Icons.account_balance_wallet,
    InvoiceCurrency.usd => Icons.attach_money,
    InvoiceCurrency.cad => Icons.payments,
  };

  @override
  Color get color => switch (this) {
    InvoiceCurrency.vnd => AppColor.green,
    InvoiceCurrency.usd => AppColor.blue,
    InvoiceCurrency.cad => AppColor.indigo,
  };

  static InvoiceCurrency? fromValue(String? value) {
    return _enumFromStringValue(
      InvoiceCurrency.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
