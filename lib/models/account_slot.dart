part of '../models.dart';

/// Account Slot
class AccountSlot {
  /// Slot ID.
  final int id;

  /// Account Master ID.
  final int accountMasterId;

  /// Slot name.
  final String name;

  /// PIN.
  final String pin;

  /// Start date.
  final DateTime? startDate;

  /// Duration in months.
  final int durationMonths;

  /// Expiry date.
  final DateTime? expiryDate;

  /// Shop order item ID.
  final int? shopOrderItemId;

  /// Notes.
  final String? notes;

  /// Whether the slot is active.
  final bool isActive;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Account master information.
  final AccountMaster? accountMaster;

  AccountSlot({
    required this.id,
    required this.accountMasterId,
    required this.name,
    required this.pin,
    this.startDate,
    required this.durationMonths,
    this.expiryDate,
    this.shopOrderItemId,
    this.notes,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.accountMaster,
  });

  factory AccountSlot.fromJson(Map<String, dynamic> map) {
    return AccountSlot(
      id: map['id']?.toInt() ?? 0,
      accountMasterId: map['account_master_id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      pin: map['pin']?.toString() ?? '',
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'].toString())
          : null,
      durationMonths: map['duration_months']?.toInt() ?? 0,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'].toString())
          : null,
      shopOrderItemId: map['shop_order_item_id']?.toInt(),
      notes: map['notes']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      accountMaster: map['account_master'] != null
          ? AccountMaster.fromJson(
              map['account_master'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_master_id': accountMasterId,
      'name': name,
      'pin': pin,
      'start_date': startDate?.toIso8601String(),
      'duration_months': durationMonths,
      'expiry_date': expiryDate?.toIso8601String(),
      'shop_order_item_id': shopOrderItemId,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'account_master': accountMaster?.toMap(),
    };
  }
}
