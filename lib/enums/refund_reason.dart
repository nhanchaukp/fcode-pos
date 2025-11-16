part of '../enums.dart';

enum RefundReason {
  customerRequest('Yêu cầu của khách hàng', 'customer_request'),
  productDefect('Sản phẩm có lỗi', 'product_defect'),
  deliveryIssue('Vấn đề giao hàng', 'delivery_issue'),
  accountExpired('Tài khoản hết hạn', 'account_expired'),
  serviceIssue('Vấn đề dịch vụ', 'service_issue'),
  other('Lý do khác', 'other');

  const RefundReason(this.label, this.value);

  final String label;
  final String value;

  static RefundReason? fromValue(String? value) {
    if (value == null) return null;
    try {
      return RefundReason.values.firstWhere((reason) => reason.value == value);
    } catch (e) {
      return null;
    }
  }
}
