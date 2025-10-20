part of '../models.dart';

/// Product pageable model for list responses with pagination
class ProductPageable extends Pageable<Product> {
  ProductPageable({required super.data, super.meta});

  factory ProductPageable.fromJson(Map<String, dynamic> map) {
    final dataList =
        (map['data'] as List?)
            ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = map['meta'] != null
        ? PaginationMeta.fromJson(map['meta'])
        : null;

    return ProductPageable(data: dataList, meta: meta);
  }

  @override
  Product parseItem(Map<String, dynamic> itemMap) => Product.fromJson(itemMap);

  @override
  Map<String, dynamic> itemToMap(Product item) => item.toMap();
}
