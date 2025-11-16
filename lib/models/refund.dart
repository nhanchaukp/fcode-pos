part of '../models.dart';

/// Refund
class Refund implements Model {
  /// Refund ID.
  final int id;

  /// Shop order ID.
  final int shopOrderId;

  /// Shop order item ID.
  final int shopOrderItemId;

  /// User ID.
  final int userId;

  /// Processed by user ID.
  final int? processedBy;

  /// Refund type (e.g., "item", "order").
  final String type;

  /// Refund status (e.g., "pending", "completed", "rejected").
  final String status;

  /// Refund reason (e.g., "customer_request", "defective_product").
  final String reason;

  /// Refund amount.
  final double amount;

  /// Refund fee.
  final double fee;

  /// Final amount after fee deduction.
  final double finalAmount;

  /// Refund description.
  final String? description;

  /// Admin notes.
  final String? adminNotes;

  /// Customer notes.
  final String? customerNotes;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  /// Processed date.
  final DateTime? processedAt;

  /// Completed date.
  final DateTime? completedAt;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Associated order.
  final Order? order;

  /// Associated order item.
  final OrderItem? orderItem;

  /// User who created the refund.
  final User? user;

  /// User who processed the refund.
  final User? processor;

  Refund({
    required this.id,
    required this.shopOrderId,
    required this.shopOrderItemId,
    required this.userId,
    this.processedBy,
    required this.type,
    required this.status,
    required this.reason,
    required this.amount,
    required this.fee,
    required this.finalAmount,
    this.description,
    this.adminNotes,
    this.customerNotes,
    this.metadata,
    this.processedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.order,
    this.orderItem,
    this.user,
    this.processor,
  });

  factory Refund.fromJson(Map<String, dynamic> map) {
    return Refund(
      id: asInt(map['id']),
      shopOrderId: asInt(map['shop_order_id']),
      shopOrderItemId: asInt(map['shop_order_item_id']),
      userId: asInt(map['user_id']),
      processedBy: asIntOrNull(map['processed_by']),
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      amount: asDouble(map['amount']),
      fee: asDouble(map['fee']),
      finalAmount: asDouble(map['final_amount']),
      description: map['description']?.toString(),
      adminNotes: map['admin_notes']?.toString(),
      customerNotes: map['customer_notes']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'].toString())
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      order: map['order'] != null
          ? Order.fromJson(map['order'] as Map<String, dynamic>)
          : null,
      orderItem: map['order_item'] != null
          ? OrderItem.fromJson(map['order_item'] as Map<String, dynamic>)
          : null,
      user: map['user'] != null
          ? User.fromJson(map['user'] as Map<String, dynamic>)
          : null,
      processor: map['processor'] != null
          ? User.fromJson(map['processor'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_order_id': shopOrderId,
      'shop_order_item_id': shopOrderItemId,
      'user_id': userId,
      'processed_by': processedBy,
      'type': type,
      'status': status,
      'reason': reason,
      'amount': amount,
      'fee': fee,
      'final_amount': finalAmount,
      'description': description,
      'admin_notes': adminNotes,
      'customer_notes': customerNotes,
      'metadata': metadata,
      'processed_at': processedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'order': order?.toMap(),
      'order_item': orderItem?.toMap(),
      'user': user?.toMap(),
      'processor': processor?.toMap(),
    };
  }
}
