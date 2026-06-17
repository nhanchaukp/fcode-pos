import 'package:fcode_pos/api/api_error_parser.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int statusCode;
  final String message;
  final dynamic data;

  String? fieldError(String field) {
    if (data is Map<String, dynamic>) {
      return firstValidationError(data as Map<String, dynamic>, field: field);
    }
    return null;
  }

  String? get firstFieldError {
    if (data is Map<String, dynamic>) {
      return firstValidationError(data as Map<String, dynamic>);
    }
    return null;
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
