part of '../enums.dart';

enum MailLogStatus implements LabeledIconEnum {
  sent('sent', 'Đã gửi'),
  pending('pending', 'Đang chờ'),
  failed('failed', 'Thất bại');

  const MailLogStatus(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    MailLogStatus.sent => Icons.check_circle_outline,
    MailLogStatus.pending => Icons.hourglass_empty,
    MailLogStatus.failed => Icons.error_outline,
  };

  @override
  Color get color => switch (this) {
    MailLogStatus.sent => AppColor.green,
    MailLogStatus.pending => AppColor.orange,
    MailLogStatus.failed => AppColor.red,
  };

  static MailLogStatus? fromValue(String? value) {
    return _enumFromStringValue(
      MailLogStatus.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }

  static MailLogStatus? fromString(String? value) {
    return fromValue(value);
  }
}
