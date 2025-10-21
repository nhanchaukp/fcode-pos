part of '../models.dart';

/// Product Supply - mapping between product and supply with pricing
class ProductSupply {
  /// Map ID.
  final int id;

  /// Product ID.
  final int productId;

  /// Supply ID.
  final int supplyId;

  /// Price from this supply.
  final int price;

  /// SKU code.
  final String? sku;

  /// Note.
  final String? note;

  /// Whether this is the preferred/default supply.
  final bool isPreferred;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Supply information.
  final Supply? supply;

  /// Product information.
  final Product? product;

  ProductSupply({
    required this.id,
    required this.productId,
    required this.supplyId,
    required this.price,
    this.sku,
    this.note,
    required this.isPreferred,
    this.createdAt,
    this.updatedAt,
    this.supply,
    this.product,
  });

  factory ProductSupply.fromJson(Map<String, dynamic> map) {
    return ProductSupply(
      id: map['id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      supplyId: map['supply_id']?.toInt() ?? 0,
      price: map['price']?.toInt() ?? 0,
      sku: map['sku']?.toString(),
      note: map['note']?.toString(),
      isPreferred: map['is_preferred'] == true || map['is_preferred'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      supply: map['supply'] != null
          ? Supply.fromJson(map['supply'] as Map<String, dynamic>)
          : null,
      product: map['product'] != null
          ? Product.fromJson(map['product'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'supply_id': supplyId,
      'price': price,
      'sku': sku,
      'note': note,
      'is_preferred': isPreferred,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (supply != null) 'supply': supply!.toMap(),
      if (product != null) 'product': product!.toMap(),
    };
  }
}
