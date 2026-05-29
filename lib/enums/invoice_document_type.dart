part of '../enums.dart';

enum InvoiceDocumentType implements LabeledIconEnum {
  draft(1, 'Hóa đơn nháp'),
  newInvoice(2, 'Hóa đơn mới'),
  cancelled(3, 'Hóa đơn đã hủy'),
  replacement(4, 'Hóa đơn thay thế'),
  replaced(5, 'Hóa đơn bị thay thế'),
  adjustmentIncrease(6, 'Hóa đơn điều chỉnh tăng'),
  adjustmentDecrease(7, 'Hóa đơn điều chỉnh giảm'),
  adjustmentInformation(8, 'Hóa đơn điều chỉnh thông tin'),
  adjustmentIncreaseDecrease(9, 'Hóa đơn điều chỉnh tăng/giảm'),
  adjusted(10, 'Hóa đơn bị điều chỉnh');

  const InvoiceDocumentType(this.value, this.label);

  final int value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    InvoiceDocumentType.draft => Icons.edit_note_outlined,
    InvoiceDocumentType.newInvoice => Icons.note_add_outlined,
    InvoiceDocumentType.cancelled => Icons.cancel_outlined,
    InvoiceDocumentType.replacement => Icons.find_replace_outlined,
    InvoiceDocumentType.replaced => Icons.compare_arrows_outlined,
    InvoiceDocumentType.adjustmentIncrease => Icons.trending_up_outlined,
    InvoiceDocumentType.adjustmentDecrease => Icons.trending_down_outlined,
    InvoiceDocumentType.adjustmentInformation => Icons.info_outline,
    InvoiceDocumentType.adjustmentIncreaseDecrease =>
      Icons.swap_vert_outlined,
    InvoiceDocumentType.adjusted => Icons.rule_folder_outlined,
  };

  @override
  Color get color => switch (this) {
    InvoiceDocumentType.draft => AppColor.orange,
    InvoiceDocumentType.newInvoice => AppColor.blue,
    InvoiceDocumentType.cancelled => AppColor.red,
    InvoiceDocumentType.replacement => AppColor.indigo,
    InvoiceDocumentType.replaced => AppColor.gray,
    InvoiceDocumentType.adjustmentIncrease => AppColor.green,
    InvoiceDocumentType.adjustmentDecrease => AppColor.orange,
    InvoiceDocumentType.adjustmentInformation => AppColor.blue,
    InvoiceDocumentType.adjustmentIncreaseDecrease => AppColor.purple,
    InvoiceDocumentType.adjusted => AppColor.teal,
  };

  static InvoiceDocumentType? fromValue(int? value) {
    return _enumFromValue(
      InvoiceDocumentType.values,
      value,
      (item) => item.value,
    );
  }
}
