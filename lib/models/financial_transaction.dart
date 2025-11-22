part of '../models.dart';

class FinancialTransaction {
  final int id;
  final String transactionId;
  final String type;
  final String category;
  final String status;
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;
  final String? transactionableType;
  final int? transactionableId;
  final int? userId;
  final int? processedBy;
  final String? description;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FinancialTransaction({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.category,
    required this.status,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.currency,
    this.transactionableType,
    this.transactionableId,
    this.userId,
    this.processedBy,
    this.description,
    this.notes,
    this.metadata,
    this.processedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: asInt(json['id']),
      transactionId: json['transaction_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: asDouble(json['amount']),
      fee: asDouble(json['fee']),
      netAmount: asDouble(json['net_amount']),
      currency: json['currency'] as String? ?? 'VND',
      transactionableType: json['transactionable_type'] as String?,
      transactionableId: asIntOrNull(json['transactionable_id']),
      userId: asIntOrNull(json['user_id']),
      processedBy: asIntOrNull(json['processed_by']),
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'category': category,
      'status': status,
      'amount': amount,
      'fee': fee,
      'net_amount': netAmount,
      'currency': currency,
      'transactionable_type': transactionableType,
      'transactionable_id': transactionableId,
      'user_id': userId,
      'processed_by': processedBy,
      'description': description,
      'notes': notes,
      'metadata': metadata,
      'processed_at': processedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
