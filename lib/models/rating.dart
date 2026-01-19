part of '../models.dart';

/// Rateable item info (product, order, etc.)
class Rateable {
  /// Rateable ID.
  final int id;

  /// Rateable type (e.g., "ShopProduct", "ShopOrder").
  final String type;

  /// Rateable name.
  final String name;

  Rateable({required this.id, required this.type, required this.name});

  factory Rateable.fromJson(Map<String, dynamic> map) {
    return Rateable(
      id: asInt(map['id']),
      type: map['type']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'type': type, 'name': name};
  }
}

/// Rating
class Rating implements Model {
  /// Rating ID.
  final int id;

  /// Rating score (1-5).
  final int rating;

  /// Rating comment.
  final String? comment;

  /// Approval status.
  final bool approved;

  /// User who created the rating.
  final User? user;

  /// Rateable item.
  final Rateable? rateable;

  /// Rateable type (e.g., "ShopProduct").
  final String rateableType;

  /// Rateable ID.
  final int rateableId;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  Rating({
    required this.id,
    required this.rating,
    this.comment,
    required this.approved,
    this.user,
    this.rateable,
    required this.rateableType,
    required this.rateableId,
    this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> map) {
    return Rating(
      id: asInt(map['id']),
      rating: asInt(map['rating']),
      comment: map['comment']?.toString(),
      approved:
          map['approved'] == 1 ||
          map['approved'] == true ||
          map['approved'] == '1',
      user: map['user'] != null
          ? User.fromJson(map['user'] as Map<String, dynamic>)
          : null,
      rateable: map['rateable'] != null
          ? Rateable.fromJson(map['rateable'] as Map<String, dynamic>)
          : null,
      rateableType: map['rateable_type']?.toString() ?? '',
      rateableId: asInt(map['rateable_id']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'approved': approved ? 1 : 0,
      'user': user?.toMap(),
      'rateable': rateable?.toMap(),
      'rateable_type': rateableType,
      'rateable_id': rateableId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
