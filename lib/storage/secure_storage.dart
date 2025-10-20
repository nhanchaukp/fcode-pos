import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  static Future<void> saveTokens(String access, String? refresh) async {
    await _storage.write(key: _keyAccessToken, value: access);
    if (refresh != null) {
      await _storage.write(key: _keyRefreshToken, value: refresh);
    }
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);
  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
