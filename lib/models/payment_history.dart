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

  /// Related paymentable record (eg. bank transaction).
  final Paymentable? paymentable;

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
    this.paymentable,
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
      paymentable: map['paymentable'] != null
          ? Paymentable.fromJson(ensureMap(map['paymentable']))
          : null,
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
      if (paymentable != null) 'paymentable': paymentable!.toMap(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Bank transaction / paymentable model.
class Paymentable {
  final int id;
  final int transactionNumber;
  final String gateway;
  final DateTime? transactionDate;
  final String accountNumber;
  final String code;
  final String content;
  final String transferType;
  final int transferAmount;
  final int accumulated;
  final String subAccount;
  final String referenceCode;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Paymentable({
    required this.id,
    required this.transactionNumber,
    required this.gateway,
    required this.transactionDate,
    required this.accountNumber,
    required this.code,
    required this.content,
    required this.transferType,
    required this.transferAmount,
    required this.accumulated,
    required this.subAccount,
    required this.referenceCode,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Paymentable.fromJson(Map<String, dynamic> map) {
    return Paymentable(
      id: asInt(map['id']),
      transactionNumber: asInt(map['transactionNumber']),
      gateway: map['gateway']?.toString() ?? '',
      transactionDate: map['transactionDate'] != null
          ? DateTime.tryParse(map['transactionDate'].toString())
          : null,
      accountNumber: map['accountNumber']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      transferType: map['transferType']?.toString() ?? '',
      transferAmount: asInt(map['transferAmount']),
      accumulated: asInt(map['accumulated']),
      subAccount: map['subAccount']?.toString() ?? '',
      referenceCode: map['referenceCode']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionNumber': transactionNumber,
      'gateway': gateway,
      'transactionDate': transactionDate?.toIso8601String(),
      'accountNumber': accountNumber,
      'code': code,
      'content': content,
      'transferType': transferType,
      'transferAmount': transferAmount,
      'accumulated': accumulated,
      'subAccount': subAccount,
      'referenceCode': referenceCode,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

