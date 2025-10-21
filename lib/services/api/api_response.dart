typedef JsonParser<T> = T Function(dynamic json);

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    JsonParser<T?>? parser,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: _parseSuccess(json['success']),
      message: json['message'] as String?,
      data: parser != null ? parser(json['data']) : json['data'] as T?,
      statusCode: statusCode,
    );
  }

  ApiResponse<R> map<R>(R? Function(T? data) transform) {
    return ApiResponse<R>(
      success: success,
      message: message,
      statusCode: statusCode,
      data: transform(data),
    );
  }

  static bool _parseSuccess(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }
}

class PaginatedData<T> {
  const PaginatedData({
    required this.items,
    required this.pagination,
  });

  final List<T> items;
  final Pagination pagination;

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    JsonParser<T> itemParser,
  ) {
    final rawItems = json['items'] ?? json['data'];
    final items = rawItems is List
        ? rawItems.map(itemParser).toList(growable: false)
        : <T>[];

    return PaginatedData<T>(
      items: items,
      pagination: Pagination.fromJson(
        (json['pagination'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }
}

class Pagination {
  const Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    return Pagination(
      total: toInt(json['total']),
      perPage: toInt(json['per_page']),
      currentPage: toInt(json['current_page']),
      lastPage: toInt(json['last_page']),
    );
  }
}
