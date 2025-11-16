part of '../enums.dart';

enum RefundStatus {
  pending('Chờ xử lý', 'pending'),
  approved('Đã duyệt', 'approved'),
  rejected('Từ chối', 'rejected'),
  completed('Hoàn thành', 'completed');

  const RefundStatus(this.label, this.value);

  final String label;
  final String value;

  static RefundStatus? fromValue(String? value) {
    if (value == null) return null;
    try {
      return RefundStatus.values.firstWhere((status) => status.value == value);
    } catch (e) {
      return null;
    }
  }
}
