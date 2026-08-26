import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';

/// Data class holding form state for adding or updating an [OrderItem].
class OrderItemFormData {
  int? id;
  Product? product;
  Supply? supply;
  int quantity;
  int price;
  int priceSupply;
  Map<String, dynamic>? account;
  AccountSlot? accountSlot;
  String? note;
  DateTime? expiredAt;

  final TextEditingController priceSupplyController;
  final TextEditingController priceController;

  OrderItemFormData({
    this.id,
    this.product,
    this.supply,
    this.quantity = 1,
    this.price = 0,
    this.priceSupply = 0,
    this.account,
    this.accountSlot,
    this.note,
    this.expiredAt,
  })  : priceSupplyController = TextEditingController(
          text: priceSupply.toString(),
        ),
        priceController = TextEditingController(text: price.toString());

  /// Create from existing [OrderItem] (for update mode)
  factory OrderItemFormData.fromOrderItem(OrderItem? item) {
    if (item == null) {
      return OrderItemFormData();
    }
    return OrderItemFormData(
      id: item.id,
      product: item.product,
      supply: item.supply,
      quantity: item.quantity,
      price: item.price,
      priceSupply: item.priceSupply,
      account: item.account,
      accountSlot: item.accountSlot,
      note: item.note,
      expiredAt: item.expiredAt,
    );
  }

  void dispose() {
    priceSupplyController.dispose();
    priceController.dispose();
  }

  /// Convert to [OrderItem] for API submission
  OrderItem toOrderItem(int? orderId) {
    return OrderItem(
      id: id,
      orderId: orderId ?? 0,
      productId: product!.id,
      supplyId: supply!.id,
      quantity: quantity,
      price: price,
      priceSupply: priceSupply,
      account: account,
      accountSlotId: accountSlot?.id,
      note: note?.isEmpty == true ? null : note,
      refundedAmount: 0,
      expiredAt: expiredAt,
    );
  }

  /// Create a copy with updated fields
  OrderItemFormData copyWith({
    int? id,
    Product? product,
    Supply? supply,
    int? quantity,
    int? price,
    int? priceSupply,
    Map<String, dynamic>? account,
    AccountSlot? accountSlot,
    String? note,
    DateTime? expiredAt,
  }) {
    return OrderItemFormData(
      id: id ?? this.id,
      product: product ?? this.product,
      supply: supply ?? this.supply,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      priceSupply: priceSupply ?? this.priceSupply,
      account: account ?? this.account,
      accountSlot: accountSlot ?? this.accountSlot,
      note: note ?? this.note,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }

  String toMap() {
    return {
      'id': id,
      'productId': product?.id,
      'supplyId': supply?.id,
      'quantity': quantity,
      'price': price,
      'priceSupply': priceSupply,
      'account': account,
      'accountSlotId': accountSlot?.id,
      'note': note,
      'expiredAt': expiredAt?.toIso8601String(),
    }.toString();
  }
}
