part of '../models.dart';

/// Supply
class Supply {
  /// Supply ID.
  final int id;

  /// Supply name.
  final String name;

  /// Supply content.
  final String? content;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  Supply({
    required this.id,
    required this.name,
    this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory Supply.fromJson(Map<String, dynamic> map) {
    return Supply(
      id: map['id'],
      name: map['name']?.toString() ?? '',
      content: map['content']?.toString(),
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
      'name': name,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
