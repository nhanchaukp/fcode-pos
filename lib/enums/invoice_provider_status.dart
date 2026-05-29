part of '../enums.dart';

enum InvoiceProviderStatus implements LabeledIconEnum {
  draft(1, 'Nháp'),
  signError(2, 'Lỗi ký'),
  notSentToTaxAuthority(3, 'Chưa gửi CQT'),
  acceptedOrGrantedCode(4, 'Đã cấp mã/tiếp nhận'),
  waitingTaxAuthorityResponse(5, 'CQT chưa phản hồi'),
  insufficientConditionsForCode(6, 'Không đủ ĐK cấp mã'),
  form04ssNotCreated(7, '[04/SS] Chưa tạo tờ khai'),
  form04ssNotAccepted(8, '[04/SS] CQT chưa tiếp nhận'),
  form04ssApproved(9, '[04/SS] CQT đã phê duyệt');

  const InvoiceProviderStatus(this.value, this.label);

  final int value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    InvoiceProviderStatus.draft => Icons.edit_note_outlined,
    InvoiceProviderStatus.signError => Icons.error_outline,
    InvoiceProviderStatus.notSentToTaxAuthority => Icons.outbox_outlined,
    InvoiceProviderStatus.acceptedOrGrantedCode => Icons.verified_outlined,
    InvoiceProviderStatus.waitingTaxAuthorityResponse =>
      Icons.hourglass_empty_outlined,
    InvoiceProviderStatus.insufficientConditionsForCode =>
      Icons.gpp_bad_outlined,
    InvoiceProviderStatus.form04ssNotCreated => Icons.note_add_outlined,
    InvoiceProviderStatus.form04ssNotAccepted =>
      Icons.mark_email_unread_outlined,
    InvoiceProviderStatus.form04ssApproved => Icons.task_alt_outlined,
  };

  @override
  Color get color => switch (this) {
    InvoiceProviderStatus.draft => AppColor.orange,
    InvoiceProviderStatus.signError => AppColor.red,
    InvoiceProviderStatus.notSentToTaxAuthority => AppColor.indigo,
    InvoiceProviderStatus.acceptedOrGrantedCode => AppColor.green,
    InvoiceProviderStatus.waitingTaxAuthorityResponse => AppColor.amber,
    InvoiceProviderStatus.insufficientConditionsForCode => AppColor.red,
    InvoiceProviderStatus.form04ssNotCreated => AppColor.blue,
    InvoiceProviderStatus.form04ssNotAccepted => AppColor.orange,
    InvoiceProviderStatus.form04ssApproved => AppColor.green,
  };

  static InvoiceProviderStatus? fromValue(int? value) {
    return _enumFromValue(
      InvoiceProviderStatus.values,
      value,
      (item) => item.value,
    );
  }
}
