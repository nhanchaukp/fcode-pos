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
  final String? monthlyCost;

  /// Cost notes.
  final String? costNotes;

  /// Whether the account is active.
  final bool isActive;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Cookies.
  final String? cookies;

  /// Details.
  final String? details;

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
    this.createdAt,
    this.updatedAt,
    this.cookies,
    this.details,
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
      monthlyCost: map['monthly_cost']?.toString(),
      costNotes: map['cost_notes']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      cookies: map['cookies']?.toString(),
      details: map['details']?.toString(),
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cookies': cookies,
      'details': details,
    };
  }
}
