part of '../models.dart';

/// Payment History
class PaymentHistory {
  /// Payment ID.
  final int id;

  /// Paymentable type.
  final String paymentableType;

  /// Paymentable ID.
  final int paymentableId;

  /// Shop order ID.
  final int shopOrderId;

  /// Amount.
  final int amount;

  /// Currency.
  final String currency;

  /// Payment status.
  final String status;

  /// Notes.
  final String? notes;

  /// Payment method.
  final String? paymentMethod;

  /// Transaction reference.
  final String? transactionReference;

  /// Payment metadata.
  final Map<String, dynamic>? metadata;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  PaymentHistory({
    required this.id,
    required this.paymentableType,
    required this.paymentableId,
    required this.shopOrderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.notes,
    this.paymentMethod,
    this.transactionReference,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> map) {
    return PaymentHistory(
      id: map['id'],
      paymentableType: map['paymentable_type']?.toString() ?? '',
      paymentableId: asInt(map['paymentable_id']),
      shopOrderId: asInt(map['shop_order_id']),
      amount: asInt(map['amount']),
      currency: map['currency']?.toString() ?? 'VND',
      status: map['status']?.toString() ?? '',
      notes: map['notes']?.toString(),
      paymentMethod: map['payment_method']?.toString(),
      transactionReference: map['transaction_reference']?.toString(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentable_type': paymentableType,
      'paymentable_id': paymentableId,
      'shop_order_id': shopOrderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'notes': notes,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
