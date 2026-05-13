part of '../enums.dart';

enum OrderStatus implements LabeledIconEnum {
  all('', 'Tất cả', AppColor.gray),
  new_('new', 'Mới', AppColor.blue),
  paymentSuccess('payment_success', 'Đã thanh toán', AppColor.teal),
  processing('processing', 'Đang xử lý', AppColor.orange),
  complete('complete', 'Hoàn thành', AppColor.green),
  cancel('cancel', 'Hủy', AppColor.red),
  underWarranty('under_warranty', 'Bảo hành', AppColor.purple),
  refund('refund', 'Hoàn tiền', AppColor.red);

  const OrderStatus(this.value, this.label, this.color);

  final String value;

  @override
  final String label;

  @override
  final Color color;

  @override
  IconData get icon => switch (this) {
    OrderStatus.all => Icons.list,
    OrderStatus.new_ => Icons.fiber_new,
    OrderStatus.paymentSuccess => Icons.check_circle,
    OrderStatus.processing => Icons.autorenew,
    OrderStatus.complete => Icons.done_all,
    OrderStatus.cancel => Icons.cancel,
    OrderStatus.underWarranty => Icons.verified_user,
    OrderStatus.refund => Icons.undo,
  };

  static OrderStatus? fromValue(String? value) {
    return _enumFromStringValue(
      OrderStatus.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
      allowEmpty: true,
    );
  }

  static List<String> getAllValues() {
    return OrderStatus.values.map((item) => item.value).toList(growable: false);
  }

  static bool isValid(String value) {
    return fromValue(value) != null;
  }
}
