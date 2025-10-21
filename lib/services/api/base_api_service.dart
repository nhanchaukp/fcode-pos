import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/storage/secure_storage.dart';

class BaseApiService {
  BaseApiService({String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? Environment.apiEndpoint,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ API Error: ${error.message}');
          debugPrint('   URL: ${error.requestOptions.uri}');
          handler.next(error);
        },
      ),
    ]);
  }

  late final Dio dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    JsonParser<T?>? parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T?>? parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T?>? parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T?>? parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() action,
    JsonParser<T?>? parser,
  ) async {
    try {
      final response = await action();
      return _parseResponse(response, parser);
    } on DioException catch (error) {
      throw await _mapDioException(error);
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    JsonParser<T?>? parser,
  ) {
    final raw = response.data;

    if (raw is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode ?? 0,
        message: 'Định dạng dữ liệu không hợp lệ từ máy chủ',
        data: raw,
      );
    }

    final apiResponse = ApiResponse<T>.fromJson(
      raw,
      parser: parser,
      statusCode: response.statusCode,
    );

    if (!apiResponse.success) {
      throw ApiException(
        statusCode: response.statusCode ?? 0,
        message: apiResponse.message ?? 'Yêu cầu không thành công',
        data: raw,
      );
    }

    return apiResponse;
  }

  Future<ApiException> _mapDioException(DioException error) async {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      final responseData = response.data;

      if (statusCode == 401) {
        await SecureStorage.clear();
      }

      final message = _extractErrorMessage(responseData, statusCode);

      return ApiException(
        statusCode: statusCode,
        message: message,
        data: responseData,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          statusCode: 408,
          message:
              'Hết thời gian chờ kết nối. Vui lòng kiểm tra mạng và thử lại.',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return ApiException(
          statusCode: 0,
          message: error.message ??
              'Không thể hoàn thành yêu cầu. Vui lòng thử lại sau.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          statusCode: 499,
          message: 'Yêu cầu đã bị huỷ.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          statusCode: 0,
          message:
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        );
    }
  }

  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ??
          data['error'] ??
          data['detail'] ??
          data['msg'] ??
          data['errors'];

      if (message != null) {
        if (message is String) return message;
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }

    return _defaultErrorMessage(statusCode);
  }

  String _defaultErrorMessage(int statusCode) {
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
