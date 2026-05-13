part of '../enums.dart';

enum RefundReason implements LabeledIconEnum {
  customerRequest('Yêu cầu của khách hàng', 'customer_request'),
  productDefect('Sản phẩm có lỗi', 'product_defect'),
  deliveryIssue('Vấn đề giao hàng', 'delivery_issue'),
  accountExpired('Tài khoản hết hạn', 'account_expired'),
  serviceIssue('Vấn đề dịch vụ', 'service_issue'),
  other('Lý do khác', 'other');

  const RefundReason(this.label, this.value);

  @override
  final String label;
  final String value;

  @override
  IconData get icon => switch (this) {
    RefundReason.customerRequest => Icons.person,
    RefundReason.productDefect => Icons.report_problem,
    RefundReason.deliveryIssue => Icons.local_shipping,
    RefundReason.accountExpired => Icons.access_time,
    RefundReason.serviceIssue => Icons.build,
    RefundReason.other => Icons.more_horiz,
  };

  @override
  Color get color => switch (this) {
    RefundReason.customerRequest => AppColor.blue,
    RefundReason.productDefect => AppColor.red,
    RefundReason.deliveryIssue => AppColor.orange,
    RefundReason.accountExpired => AppColor.amber,
    RefundReason.serviceIssue => AppColor.pink,
    RefundReason.other => AppColor.gray,
  };

  static RefundReason? fromValue(String? value) {
    return _enumFromStringValue(
      RefundReason.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
