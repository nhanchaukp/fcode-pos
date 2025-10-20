part of '../enums.dart';

enum OrderStatus {
  all('', 'Tất cả', Colors.grey),
  new_('new', 'Mới', Colors.blue),
  paymentSuccess('payment_success', 'Đã thanh toán', Colors.teal),
  processing('processing', 'Đang xử lý', Colors.orange),
  complete('complete', 'Hoàn thành', Colors.green),
  cancel('cancel', 'Hủy', Colors.red),
  underWarranty('under_warranty', 'Bảo hành', Colors.purple),
  refund('refund', 'Hoàn tiền', Colors.red);

  final String value;
  final String label;
  final Color color;

  const OrderStatus(this.value, this.label, this.color);

  /// Lấy giá trị raw
  static OrderStatus? fromString(String? value) {
    if (value == null) return null;
    try {
      return OrderStatus.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }

  /// Tất cả giá trị dưới dạng list string
  static List<String> getAllValues() {
    return OrderStatus.values.map((e) => e.value).toList();
  }

  /// Check xem value có hợp lệ không
  static bool isValid(String value) {
    return OrderStatus.values.any((e) => e.value == value);
  }
}
