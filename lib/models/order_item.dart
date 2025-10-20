part of '../models.dart';

/// Order Item
class OrderItem {
  /// Item ID.
  final int? id;

  /// Order ID.
  final int orderId;

  /// Product ID.
  final int productId;

  /// Item note.
  final String? note;

  /// Quantity.
  final int quantity;

  /// Account information.
  final Map<String, dynamic>? account;

  /// Price.
  final int price;

  /// Supply price.
  final int priceSupply;

  /// Supply ID.
  final int supplyId;

  /// Account slot ID.
  final int? accountSlotId;

  /// Expiration date.
  final DateTime? expiredAt;

  /// Whether notified.
  final bool? notified;

  /// Refund status.
  final String? refundStatus;

  /// Refunded amount.
  final int refundedAmount;

  /// Refund date.
  final DateTime? refundedAt;

  /// Refund reason.
  final String? refundReason;

  /// Refund metadata.
  final Map<String, dynamic>? refundMetadata;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Notification date.
  final DateTime? notifiedAt;

  /// Product information.
  final Product? product;

  /// Account slot information.
  final AccountSlot? accountSlot;

  /// Supply information.
  final Supply? supply;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    this.note,
    required this.quantity,
    this.account,
    required this.price,
    required this.priceSupply,
    required this.supplyId,
    this.accountSlotId,
    this.expiredAt,
    this.notified,
    this.refundStatus,
    required this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.refundMetadata,
    this.createdAt,
    this.updatedAt,
    this.notifiedAt,
    this.product,
    this.accountSlot,
    this.supply,
  });

  factory OrderItem.fromJson(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toInt() ?? 0,
      orderId: map['order_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      note: map['note']?.toString(),
      quantity: map['quantity']?.toInt() ?? 0,
      account: map['account'] is Map<String, dynamic>
          ? map['account'] as Map<String, dynamic>
          : null,
      price: int.tryParse(map['price']?.toString() ?? '0') ?? 0,
      priceSupply: int.tryParse(map['price_supply']?.toString() ?? '0') ?? 0,
      supplyId: map['supply_id']?.toInt() ?? 0,
      accountSlotId: map['account_slot_id']?.toInt(),
      expiredAt: map['expired_at'] != null
          ? DateTime.parse(map['expired_at'].toString())
          : null,
      notified: map['notified'] == true || map['notified'] == 1,
      refundStatus: map['refund_status']?.toString() ?? 'none',
      refundedAmount:
          int.tryParse(map['refunded_amount']?.toString() ?? '0') ?? 0,
      refundedAt: map['refunded_at'] != null
          ? DateTime.parse(map['refunded_at'].toString())
          : null,
      refundReason: map['refund_reason']?.toString(),
      refundMetadata: map['refund_metadata'] is Map<String, dynamic>
          ? map['refund_metadata'] as Map<String, dynamic>
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      notifiedAt: map['notified_at'] != null
          ? DateTime.parse(map['notified_at'].toString())
          : null,
      product: map['product'] != null
          ? Product.fromJson(map['product'] as Map<String, dynamic>)
          : null,
      accountSlot: map['account_slot'] != null
          ? AccountSlot.fromJson(map['account_slot'] as Map<String, dynamic>)
          : null,
      supply: map['supply'] != null
          ? Supply.fromJson(map['supply'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'note': note,
      'quantity': quantity,
      'account': account,
      'price': price,
      'price_supply': priceSupply,
      'supply_id': supplyId,
      'account_slot_id': accountSlotId,
      'expired_at': expiredAt?.toIso8601String(),
      'notified': notified,
      'refund_status': refundStatus,
      'refunded_amount': refundedAmount,
      'refunded_at': refundedAt?.toIso8601String(),
      'refund_reason': refundReason,
      'refund_metadata': refundMetadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notified_at': notifiedAt?.toIso8601String(),
      'product': product?.toMap(),
      'account_slot': accountSlot?.toMap(),
      'supply': supply?.toMap(),
    };
  }
}
