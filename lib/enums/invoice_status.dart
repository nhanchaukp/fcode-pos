part of '../enums.dart';

enum InvoiceStatus implements LabeledIconEnum {
  draft('draft', 'Nháp'),
  issued('issued', 'Đã phát hành'),
  cancelled('cancelled', 'Đã huỷ');

  const InvoiceStatus(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    InvoiceStatus.draft => Icons.edit_note_outlined,
    InvoiceStatus.issued => Icons.check_circle_outline,
    InvoiceStatus.cancelled => Icons.cancel_outlined,
  };

  @override
  Color get color => switch (this) {
    InvoiceStatus.draft => AppColor.orange,
    InvoiceStatus.issued => AppColor.green,
    InvoiceStatus.cancelled => AppColor.red,
  };

  static InvoiceStatus? fromValue(String? value) {
    return _enumFromStringValue(
      InvoiceStatus.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }

  static InvoiceStatus? fromString(String? value) {
    return fromValue(value);
  }
}
