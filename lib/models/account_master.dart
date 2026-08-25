part of '../models.dart';

/// Account Master
class AccountMaster {
  /// Account Master ID.
  final int id;

  /// Account name.
  final String name;

  /// Username.
  final String username;

  /// Password.
  final String password;

  /// Service type.
  final String serviceType;

  /// Maximum number of slots.
  final int maxSlots;

  /// Notes.
  final String? notes;

  /// Payment date.
  final DateTime? paymentDate;

  /// Monthly cost.
  final int? monthlyCost;

  /// Cost notes.
  final String? costNotes;

  /// Whether the account is active.
  final bool isActive;

  /// Whether the account allow show password for access link of slot show
  final bool showPassword;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Cookies.
  final String? cookies;

  /// Details.
  final String? details;

  final List<AccountSlot>? slots;

  final int? slotsCount;

  final String? externalSrc;
  final Map<String, dynamic>? externalConfig;

  final Supply? supply;

  final bool? hasExpenseThisMonth;

  final String? twoFactorSecret;

  AccountMaster({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.serviceType,
    required this.maxSlots,
    this.notes,
    this.paymentDate,
    this.monthlyCost,
    this.costNotes,
    required this.isActive,
    required this.showPassword,
    this.createdAt,
    this.updatedAt,
    this.cookies,
    this.details,
    this.slots,
    this.slotsCount,
    this.externalSrc,
    this.externalConfig,
    this.supply,
    this.hasExpenseThisMonth,
    this.twoFactorSecret,
  });

  factory AccountMaster.fromJson(Map<String, dynamic> map) {
    return AccountMaster(
      id: map['id'],
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      serviceType: map['service_type']?.toString() ?? '',
      maxSlots: asInt(map['max_slots']),
      notes: map['notes']?.toString(),
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'].toString())
          : null,
      monthlyCost: asInt(map['monthly_cost']),
      costNotes: map['cost_notes']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      showPassword: map['show_password'] == true || map['show_password'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      cookies: map['cookies']?.toString(),
      details: map['details']?.toString(),
      slots: map['slots'] is List
          ? (map['slots'] as List)
                .map((item) => AccountSlot.fromJson(ensureMap(item)))
                .toList(growable: false)
          : null,
      slotsCount: asInt(map['slots_count']),
      externalSrc: map['external_src']?.toString(),
      externalConfig: map['external_config'] != null
          ? map['external_config'] as Map<String, dynamic>
          : null,
      supply: map['supply'] != null
          ? Supply.fromJson(map['supply'] as Map<String, dynamic>)
          : null,
      hasExpenseThisMonth:
          map['has_expense_this_month'] == true ||
              map['has_expense_this_month'] == 1
          ? true
          : null, // null means not checked yet
      twoFactorSecret: map['two_factor_secret']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'service_type': serviceType,
      'max_slots': maxSlots,
      'notes': notes,
      'payment_date': paymentDate?.toIso8601String(),
      'monthly_cost': monthlyCost,
      'cost_notes': costNotes,
      'is_active': isActive,
      'show_password': showPassword,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cookies': cookies,
      'details': details,
      'slots': slots?.map((slot) => slot.toMap()).toList(),
      'slots_count': slotsCount,
      'external_src': externalSrc,
      'external_config': externalConfig,
      'supply': supply?.toMap(),
      'has_expense_this_month': hasExpenseThisMonth,
      'two_factor_secret': twoFactorSecret,
    };
  }
}
