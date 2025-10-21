part of '../models.dart';

/// Type definition for fromJson factory method
/// Used for deserializing JSON/Map to Model instances
typedef FromJson<T extends Model> = T Function(Map<String, dynamic> json);

abstract class Model {
  /// Convert model to Map for serialization
  Map<String, dynamic> toMap();

  /// Each subclass must implement a factory constructor for deserialization:
  /// ```dart
  /// factory ClassName.fromJson(Map<String, dynamic> json) => ClassName(
  ///   id: json['id'],
  ///   name: json['name'],
  ///   // ... other fields
  /// );
  /// ```
}

/// Extension to provide JSON parsing utilities for Model
extension ModelExtension on Model {
  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());
}

/// Helper for parsing lists of models
extension ModelListExtension<T extends Model> on List<Map<String, dynamic>> {
  /// Parse a list of JSON maps to a list of models
  /// Usage: jsonList.parseModels(User.fromJson)
  List<T> parseModels(FromJson<T> fromJson) {
    return map((json) => fromJson(json)).toList();
  }
}
