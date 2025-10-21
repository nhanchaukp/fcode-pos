class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int statusCode;
  final String message;
  final dynamic data;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
