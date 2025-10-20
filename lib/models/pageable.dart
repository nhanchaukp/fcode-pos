part of '../models.dart';

/// Pagination link
class PaginationLink {
  /// URL for the link
  final String? url;

  /// Label for the link
  final String? label;

  /// Whether this link is active
  final bool? active;

  PaginationLink({this.url, this.label, this.active});

  factory PaginationLink.fromJson(Map<String, dynamic> map) {
    return PaginationLink(
      url: map['url']?.toString(),
      label: map['label']?.toString(),
      active: map['active'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'label': label, 'active': active};
  }
}

/// Pagination metadata
class PaginationMeta {
  /// Current page number
  final int currentPage;

  /// Starting record number
  final int from;

  /// Last page number
  final int lastPage;

  /// Links for pagination
  final List<PaginationLink> links;

  /// API path
  final String path;

  /// Items per page
  final int perPage;

  /// Ending record number
  final int to;

  /// Total number of records
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> map) {
    return PaginationMeta(
      currentPage: map['current_page']?.toInt() ?? 0,
      from: map['from']?.toInt() ?? 0,
      lastPage: map['last_page']?.toInt() ?? 0,
      links: List<PaginationLink>.from(
        (map['links'] as List?)?.map((e) => PaginationLink.fromJson(e)) ?? [],
      ),
      path: map['path']?.toString() ?? '',
      perPage: map['per_page']?.toInt() ?? 0,
      to: map['to']?.toInt() ?? 0,
      total: map['total']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_page': currentPage,
      'from': from,
      'last_page': lastPage,
      'links': links.map((e) => e.toMap()).toList(),
      'path': path,
      'per_page': perPage,
      'to': to,
      'total': total,
    };
  }
}

/// Pageable base class for models with pagination support
/// Models that extend this class should provide:
/// - T: The type of items in the list
/// - parseData: A function to parse the data list from the map
abstract class Pageable<T> implements Model {
  /// List of items
  final List<T> data;

  /// Pagination metadata
  final PaginationMeta? meta;

  Pageable({required this.data, this.meta});

  /// Parse individual item from map - must be implemented by subclasses
  T parseItem(Map<String, dynamic> itemMap);

  /// Convert item to map - must be implemented by subclasses
  Map<String, dynamic> itemToMap(T item);

  /// Create pageable instance from map
  /// Expects structure: { "data": [...], "meta": {...} }
  factory Pageable.fromJson(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) parser,
  ) {
    // This is a factory that should be overridden by subclasses
    throw UnimplementedError('Use subclass factory instead');
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'data': data.map((item) => itemToMap(item)).toList(),
      'meta': meta?.toMap(),
    };
  }
}
