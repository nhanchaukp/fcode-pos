import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:fcode_pos/api/api_error_parser.dart';
import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/login_result.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';
import 'package:fcode_pos/storage/user_prefs.dart';

class AuthService {
  AuthService() : _api = ApiService() {
    _authDio = Dio(
      BaseOptions(
        baseUrl: Environment.apiEndpoint,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _cookieJar = CookieJar();
    _authDio.interceptors.add(CookieManager(_cookieJar));
  }

  final ApiService _api;
  late final Dio _authDio;
  late final CookieJar _cookieJar;

  Future<LoginResult> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    try {
      final response = await _authDio.post<dynamic>(
        '/auth/login',
        data: {'email': email, 'password': password, 'remember': remember},
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Định dạng dữ liệu không hợp lệ từ máy chủ',
          data: raw,
        );
      }

      if (raw['two_factor'] == true) {
        return LoginResult.requiresTwoFactor();
      }

      final user = await _persistAuthPayload(raw);
      return LoginResult.success(user);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<User> verifyTwoFactor({String? code, String? recoveryCode}) async {
    try {
      final response = await _authDio.post<dynamic>(
        '/auth/two-factor-challenge',
        data: {
          if (code != null && code.isNotEmpty) 'code': code,
          if (recoveryCode != null && recoveryCode.isNotEmpty)
            'recovery_code': recoveryCode,
        },
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          message: 'Định dạng dữ liệu không hợp lệ từ máy chủ',
          data: raw,
        );
      }

      return _persistAuthPayload(raw);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<void> clearAuthSession() async {
    try {
      await _cookieJar.deleteAll();
    } catch (_) {}
  }

  Future<ApiResponse<User>> getUserInfo() async {
    final response = await _api.get<User>(
      '/user/me',
      parser: (json) => User.fromJson(ensureMap(json)),
    );

    final user = response.data;
    if (user != null) {
      await UserPrefs.saveUser(user);
    }

    return response;
  }

  Future<void> logout() async {
    try {
      await NotificationService.instance.deleteTokenFromServer();
    } catch (_) {}
    await clearAuthSession();
    await SecureStorage.clear();
    await UserPrefs.clear();
  }

  Future<ApiResponse<PasskeyOptions>> getPasskeyOptions() {
    return _api.get<PasskeyOptions>(
      '/auth/passkeys/options',
      parser: (json) => PasskeyOptions.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<User>> loginWithPasskey(
    Map<String, dynamic> passkeyResponse,
  ) async {
    final response = await _api.post<LoginResponse>(
      '/auth/passkeys/authenticate',
      data: {'start_authentication_response': passkeyResponse},
      parser: (json) => LoginResponse.fromJson(ensureMap(json)),
    );

    final payload = response.data;
    if (payload != null) {
      await SecureStorage.saveTokens(payload.accessToken, null);
      await UserPrefs.saveUser(payload.user);
    }

    return response.map((payload) => payload?.user);
  }

  Future<User> _persistAuthPayload(Map<String, dynamic> raw) async {
    if (raw['success'] != true) {
      throw ApiException(
        statusCode: 200,
        message: raw['message']?.toString() ?? 'Đăng nhập thất bại',
        data: raw,
      );
    }

    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 200,
        message: 'Thiếu dữ liệu đăng nhập từ máy chủ',
        data: raw,
      );
    }

    final accessToken = data['access_token']?.toString() ?? '';
    if (accessToken.isEmpty) {
      throw ApiException(
        statusCode: 200,
        message: 'Không nhận được access token',
        data: raw,
      );
    }

    final userMap = data['user'];
    if (userMap is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 200,
        message: 'Thiếu thông tin người dùng từ máy chủ',
        data: raw,
      );
    }

    final user = User.fromJson(userMap);
    await SecureStorage.saveTokens(accessToken, null);
    await UserPrefs.saveUser(user);
    await clearAuthSession();
    return user;
  }

  ApiException _mapDioException(DioException error) {
    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      return ApiException(
        statusCode: statusCode,
        message: extractApiErrorMessage(response.data, statusCode),
        data: response.data,
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
      default:
        return ApiException(
          statusCode: 0,
          message:
              error.message ??
              'Không thể hoàn thành yêu cầu. Vui lòng thử lại sau.',
        );
    }
  }
}

Map<String, dynamic> ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
