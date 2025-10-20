import 'package:dio/dio.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:flutter/cupertino.dart';
import '../storage/secure_storage.dart';
import '../exceptions/api_exception.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String apiEndpoint = Environment.apiEndpoint;
  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: apiEndpoint,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.addAll([
      LogInterceptor(responseBody: true),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token if exists
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // Log error for debugging
          debugPrint('❌ API Error: ${e.message}');
          debugPrint('   URL: ${e.requestOptions.uri}');

          // Handle 401 Unauthorized → clear token
          if (e.response?.statusCode == 401) {
            await SecureStorage.clear();
            throw ApiException(
              statusCode: 401,
              message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              data: e.response?.data,
            );
          }

          // Handle error response with status code >= 400
          if (e.response != null && e.response!.statusCode != null) {
            final statusCode = e.response!.statusCode!;
            final responseData = e.response!.data;
            String errorMessage =
                _extractErrorMessage(responseData, statusCode);

            debugPrint('   Status: $statusCode');
            debugPrint('   Message: $errorMessage');

            // Throw ApiException - let caller handle UI
            throw ApiException(
              statusCode: statusCode,
              message: errorMessage,
              data: responseData,
            );
          }

          // Handle network errors (no response)
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            throw ApiException(
              statusCode: 408,
              message:
                  'Hết thời gian chờ kết nối. Vui lòng kiểm tra mạng và thử lại.',
              data: null,
            );
          }

          if (e.type == DioExceptionType.connectionError) {
            throw ApiException(
              statusCode: 0,
              message:
                  'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
              data: null,
            );
          }

          // Unknown error
          throw ApiException(
            statusCode: 0,
            message: e.message ?? 'Đã xảy ra lỗi không xác định',
            data: null,
          );
        },
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return dio.delete(path, data: data);
  }

  /// Extract error message from response data
  String _extractErrorMessage(dynamic responseData, int statusCode) {
    // Try to extract message from response body
    if (responseData is Map<String, dynamic>) {
      // Check common error message fields
      final message = responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          responseData['msg'] ??
          responseData['errors'];

      if (message != null) {
        if (message is String) return message;
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    // Default messages based on status code
    return _getDefaultErrorMessage(statusCode);
  }

  /// Get default error message based on HTTP status code
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ';
      case 401:
        return 'Phiên đăng nhập đã hết hạn';
      case 403:
        return 'Bạn không có quyền truy cập';
      case 404:
        return 'Không tìm thấy tài nguyên';
      case 405:
        return 'Phương thức không được hỗ trợ';
      case 408:
        return 'Hết thời gian chờ';
      case 409:
        return 'Dữ liệu bị xung đột';
      case 422:
        return 'Dữ liệu không hợp lệ';
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 500:
        return 'Lỗi máy chủ';
      case 502:
        return 'Máy chủ không phản hồi';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng';
      case 504:
        return 'Máy chủ quá tải';
      default:
        return 'Đã xảy ra lỗi ($statusCode)';
    }
  }
}
