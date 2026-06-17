String extractApiErrorMessage(dynamic data, int statusCode) {
  if (data is Map<String, dynamic>) {
    final fieldError = firstValidationError(data);
    if (fieldError != null) return fieldError;

    final message =
        data['message'] ??
        data['error'] ??
        data['detail'] ??
        data['msg'];

    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      return message.map((e) => e.toString()).join(', ');
    }
  } else if (data is String && data.isNotEmpty) {
    return data;
  }

  return defaultApiErrorMessage(statusCode);
}

String? firstValidationError(Map<String, dynamic> data, {String? field}) {
  final errors = data['errors'];
  if (errors is! Map) return null;

  if (field != null) {
    final value = errors[field];
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value is String && value.isNotEmpty) return value;
  }

  for (final value in errors.values) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value is String && value.isNotEmpty) return value;
  }

  return null;
}

String defaultApiErrorMessage(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Yêu cầu không hợp lệ';
    case 401:
      return 'Phiên đăng nhập đã hết hạn';
    case 403:
      return 'Bạn không có quyền truy cập';
    case 404:
      return 'Không tìm thấy tài nguyên';
    case 408:
      return 'Hết thời gian chờ';
    case 422:
      return 'Dữ liệu không hợp lệ';
    case 429:
      return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
    case 500:
      return 'Lỗi máy chủ';
    default:
      return 'Đã xảy ra lỗi ($statusCode)';
  }
}