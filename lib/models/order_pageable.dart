part of '../models.dart';

/// Order pageable model for list responses with pagination
class OrderPageable extends Pageable<Order> {
  OrderPageable({required super.data, super.meta});

  factory OrderPageable.fromJson(Map<String, dynamic> map) {
    final dataList =
        (map['data'] as List?)
            ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = map['meta'] != null
        ? PaginationMeta.fromJson(map['meta'])
        : null;

    return OrderPageable(data: dataList, meta: meta);
  }

  @override
  Order parseItem(Map<String, dynamic> itemMap) => Order.fromJson(itemMap);

  @override
  Map<String, dynamic> itemToMap(Order item) => item.toMap();
}
