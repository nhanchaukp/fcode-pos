import 'package:dio/dio.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;

class TelegramBotApiException implements Exception {
  TelegramBotApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TelegramBotSession {
  const TelegramBotSession({required this.token, required this.username});

  final String token;
  final String username;
}

class TelegramBotSessionStorage {
  static const _tokenKey = 'telegram_bot_admin_token';
  static const _usernameKey = 'telegram_bot_admin_username';

  Future<TelegramBotSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey)?.trim() ?? '';
    final username = prefs.getString(_usernameKey)?.trim() ?? '';

    if (token.isEmpty) {
      return null;
    }

    return TelegramBotSession(
      token: token,
      username: username.isEmpty ? 'admin' : username,
    );
  }

  Future<void> save(TelegramBotSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_usernameKey, session.username);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }
}

class TelegramBotApiClient {
  TelegramBotApiClient({String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: Environment.telegramBotBaseApi,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    setToken(token);
  }

  final Dio _dio;
  String? _token;

  void setToken(String? token) {
    _token = token?.trim();
    if (_token == null || _token!.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }

    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<TelegramBotSession> login({
    required String username,
    required String password,
  }) async {
    final envelope = await _requestEnvelope(
      method: 'POST',
      path: '/api/auth/login',
      includeAuth: false,
      data: {'username': username, 'password': password},
    );

    final token = (envelope['token'] ?? '').toString().trim();
    if (token.isEmpty) {
      throw TelegramBotApiException('Đăng nhập thất bại: thiếu token trả về');
    }

    final user = _toMap(envelope['user']);
    final name = (user['username'] ?? username).toString().trim();

    setToken(token);
    return TelegramBotSession(
      token: token,
      username: name.isEmpty ? 'admin' : name,
    );
  }

  Future<JsonMap> getMe() async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/auth/me',
    );
    return _toMap(envelope['user']);
  }

  Future<List<JsonMap>> getProducts() async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/products',
    );
    return _toListOfMap(envelope['data']);
  }

  Future<void> createProduct(JsonMap payload) async {
    await _requestEnvelope(
      method: 'POST',
      path: '/api/products',
      data: payload,
    );
  }

  Future<void> updateProduct(int productId, JsonMap payload) async {
    await _requestEnvelope(
      method: 'PUT',
      path: '/api/products/$productId',
      data: payload,
    );
  }

  Future<JsonMap> getProductInventory(
    int productId, {
    String? status,
    int limit = 200,
  }) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/products/$productId/inventory',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
      },
    );
    return _toMap(envelope['data']);
  }

  Future<JsonMap> importProductInventory(
    int productId, {
    required String lines,
  }) async {
    final envelope = await _requestEnvelope(
      method: 'POST',
      path: '/api/products/$productId/inventory/import',
      data: {'lines': lines},
    );
    return _toMap(envelope['data']);
  }

  Future<JsonMap> adjustProductInventory(
    int productId, {
    required int delta,
  }) async {
    final envelope = await _requestEnvelope(
      method: 'POST',
      path: '/api/products/$productId/inventory/adjust',
      data: {'delta': delta},
    );
    return _toMap(envelope['data']);
  }

  Future<List<JsonMap>> getDucVietProducts({bool refresh = false}) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/integrations/ducviet/products',
      queryParameters: {if (refresh) 'refresh': '1'},
    );
    return _toListOfMap(envelope['data']);
  }

  Future<List<JsonMap>> getOrders({String? status, int limit = 100}) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/orders',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
      },
    );
    return _toListOfMap(envelope['data']);
  }

  Future<JsonMap> getOrderDetail(int orderId) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/orders/$orderId',
    );
    return _toMap(envelope['data']);
  }

  Future<List<JsonMap>> getUsers() async {
    final envelope = await _requestEnvelope(method: 'GET', path: '/api/users');
    return _toListOfMap(envelope['data']);
  }

  Future<JsonMap> getUserDetail(int userId) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/users/$userId',
    );
    return _toMap(envelope['data']);
  }

  Future<JsonMap> getDashboardOverview() async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/dashboard/overview',
    );
    return _toMap(envelope['data']);
  }

  Future<List<JsonMap>> getRevenueTrend({int days = 14}) async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/dashboard/revenue-trend',
      queryParameters: {'days': days},
    );
    return _toListOfMap(envelope['data']);
  }

  Future<JsonMap> getBotInfo() async {
    final envelope = await _requestEnvelope(
      method: 'GET',
      path: '/api/dashboard/bot-info',
    );
    return _toMap(envelope['data']);
  }

  Future<JsonMap> _requestEnvelope({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    bool includeAuth = true,
  }) async {
    if (includeAuth && (_token == null || _token!.isEmpty)) {
      throw TelegramBotApiException('Chưa đăng nhập Telegram Bot');
    }

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      final raw = response.data;
      if (raw is! Map) {
        throw TelegramBotApiException('Phản hồi API không hợp lệ');
      }

      final envelope = _toMap(raw);
      final ok = envelope['ok'] == true || envelope['success'] == true;
      if (!ok) {
        final message =
            (envelope['message'] ?? envelope['error'] ?? 'Yêu cầu thất bại')
                .toString();
        throw TelegramBotApiException(message, statusCode: response.statusCode);
      }

      return envelope;
    } on DioException catch (error) {
      final response = error.response;
      final responseData = response?.data;

      if (responseData is Map) {
        final map = _toMap(responseData);
        final message =
            (map['message'] ?? map['error'] ?? error.message ?? 'Lỗi kết nối')
                .toString();
        throw TelegramBotApiException(
          message,
          statusCode: response?.statusCode,
        );
      }

      throw TelegramBotApiException(
        error.message ?? 'Không thể kết nối Telegram Bot API',
        statusCode: response?.statusCode,
      );
    }
  }

  JsonMap _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  List<JsonMap> _toListOfMap(dynamic raw) {
    if (raw is! List) {
      return const <JsonMap>[];
    }

    return raw
        .whereType<Object>()
        .map((item) => _toMap(item))
        .toList(growable: false);
  }
}
