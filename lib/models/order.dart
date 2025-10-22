part of '../models.dart';

/// Order Renew Item
class RenewItem {
  /// Order ID being renewed from.
  final int orderId;

  /// Order item ID.
  final int orderItemId;

  /// Expiration date.
  final String expiredAt;

  /// New expiration date.
  final String newExpiredAt;

  RenewItem({
    required this.orderId,
    required this.orderItemId,
    required this.expiredAt,
    required this.newExpiredAt,
  });

  factory RenewItem.fromJson(Map<String, dynamic> map) {
    return RenewItem(
      orderId: map['order_id'],
      orderItemId: map['order_item_id'],
      expiredAt: map['expired_at']?.toString() ?? '',
      newExpiredAt: map['new_expired_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'order_item_id': orderItemId,
      'expired_at': expiredAt,
      'new_expired_at': newExpiredAt,
    };
  }
}

/// Order
class Order implements Model {
  /// Order ID.
  final int id;

  /// User ID.
  final int userId;

  /// Order total amount.
  final int total;

  /// Discount amount.
  final int? discount;

  /// Order status (e.g., "new", "pending", "completed").
  final String status;

  /// Order type (e.g., "renew", "purchase").
  final String type;

  /// Refund amount.
  final int? refundAmount;

  /// Order note.
  final String? note;

  /// Transaction ID.
  final String? transactionId;

  /// Order creation date in ISO 8601 format.
  final DateTime? createdAt;

  /// Order update date in ISO 8601 format.
  final DateTime? updatedAt;

  /// Payment ID.
  final String? paymentId;

  /// UTM source.
  final String? utmSource;

  /// Associated user object.
  final User? user;

  /// Order items.
  final List<OrderItem> items;

  final int itemCount;

  /// Payment histories.
  final List<PaymentHistory> paymentHistories;

  /// Refunds.
  final List<dynamic> refunds;

  Order({
    required this.id,
    required this.userId,
    required this.total,
    this.discount,
    required this.status,
    required this.type,
    this.refundAmount,
    this.note,
    this.transactionId,
    this.createdAt,
    this.updatedAt,
    this.paymentId,
    this.utmSource,
    this.user,
    this.items = const [],
    this.itemCount = 0,
    this.paymentHistories = const [],
    this.refunds = const [],
  });

  factory Order.fromJson(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: asInt(map['user_id']),
      total: asInt(map['total']),
      discount: asInt(map['discount']),
      status: map['status']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      refundAmount: asInt(map['refund_amount']),
      note: map['note']?.toString(),
      transactionId: map['transaction_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      paymentId: map['payment_id']?.toString(),
      utmSource: map['utm_source']?.toString(),
      user: map['user'] != null ? User.fromJson(map['user']) : null,
      items:
          (map['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemCount: map['item_count'],
      paymentHistories:
          (map['payment_histories'] as List?)
              ?.map((e) => PaymentHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      refunds: (map['refunds'] as List?) ?? [],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total': total,
      'discount': discount,
      'status': status,
      'type': type,
      'refund_amount': refundAmount,
      'note': note,
      'transaction_id': transactionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'payment_id': paymentId,
      'utm_source': utmSource,
      'user': user?.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'payment_histories': paymentHistories.map((e) => e.toMap()).toList(),
      'refunds': refunds,
    };
  }
}
