import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';
import 'package:fcode_pos/storage/user_prefs.dart';

class AuthService {
  AuthService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<User>> login(String email, String password) async {
    final response = await _api.post<_LoginPayload>(
      '/auth/login',
      data: {'email': email, 'password': password},
      parser: (json) => _LoginPayload.fromJson(ensureMap(json)),
    );

    final payload = response.data;
    if (payload != null) {
      await SecureStorage.saveTokens(payload.accessToken, payload.refreshToken);
      await UserPrefs.saveUser(payload.user);
    }

    return response.map((payload) => payload?.user);
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
    final response = await _api.post<_LoginPayload>(
      '/auth/passkeys/authenticate',
      data: {'start_authentication_response': passkeyResponse},
      parser: (json) => _LoginPayload.fromJson(ensureMap(json)),
    );

    final payload = response.data;
    if (payload != null) {
      await SecureStorage.saveTokens(payload.accessToken, payload.refreshToken);
      await UserPrefs.saveUser(payload.user);
    }

    return response.map((payload) => payload?.user);
  }
}

Map<String, dynamic> ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

class _LoginPayload {
  _LoginPayload({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  factory _LoginPayload.fromJson(Map<String, dynamic> json) {
    return _LoginPayload(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      user: User.fromJson(ensureMap(json['user'])),
    );
  }
}
