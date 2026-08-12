import 'package:fcode_pos/models.dart';

class OrderUpsertItemsData {
  final List<OrderItem> items;

  const OrderUpsertItemsData({
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
