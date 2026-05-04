part of '../models.dart';

/// Audit log entry from Laravel Auditing.
class Auditable {
  /// Audit ID.
  final int id;

  /// Auditable model type (e.g. "App\\Models\\Order").
  final String auditableType;

  /// Auditable model ID.
  final int auditableId;

  /// Event type (e.g. "created", "updated", "deleted").
  final String event;

  /// Previous values before the change.
  final Map<String, dynamic>? oldValues;

  /// New values after the change.
  final Map<String, dynamic>? newValues;

  /// Tags associated with the audit.
  final String? tags;

  /// URL where the event occurred.
  final String? url;

  /// IP address of the actor.
  final String? ipAddress;

  /// User agent string of the actor.
  final String? userAgent;

  /// User who performed the action.
  final User? user;

  /// Creation date.
  final String? createdAt;

  /// Update date.
  final String? updatedAt;

  Auditable({
    required this.id,
    required this.auditableType,
    required this.auditableId,
    required this.event,
    this.oldValues,
    this.newValues,
    this.tags,
    this.url,
    this.ipAddress,
    this.userAgent,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Auditable.fromJson(Map<String, dynamic> map) {
    return Auditable(
      id: asInt(map['id']),
      auditableType: map['auditable_type']?.toString() ?? '',
      auditableId: asInt(map['auditable_id']),
      event: map['event']?.toString() ?? '',
      oldValues: map['old_values'] is Map
          ? Map<String, dynamic>.from(map['old_values'] as Map)
          : null,
      newValues: map['new_values'] is Map
          ? Map<String, dynamic>.from(map['new_values'] as Map)
          : null,
      tags: map['tags']?.toString(),
      url: map['url']?.toString(),
      ipAddress: map['ip_address']?.toString(),
      userAgent: map['user_agent']?.toString(),
      user: map['user'] != null && map['user'] is Map
          ? User.fromJson(Map<String, dynamic>.from(map['user'] as Map))
          : null,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auditable_type': auditableType,
      'auditable_id': auditableId,
      'event': event,
      'old_values': oldValues,
      'new_values': newValues,
      'tags': tags,
      'url': url,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'user': user?.toMap(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
