import 'package:fcode_pos/models.dart';

class OrderCreateData {
  final int userId;
  final int total;
  final String status;
  final String type;
  final String? note;
  final String? utmSource;
  final List<OrderItem> items;

  const OrderCreateData({
    required this.userId,
    required this.total,
    required this.status,
    required this.type,
    this.note,
    this.utmSource,
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total': total,
      'status': status,
      'type': type,
      if (note != null) 'note': note,
      if (utmSource != null) 'utm_source': utmSource,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
