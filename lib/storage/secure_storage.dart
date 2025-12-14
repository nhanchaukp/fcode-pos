import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  static Future<void> saveTokens(String access, String? refresh) async {
    try {
      await _storage.write(key: _keyAccessToken, value: access);
      if (refresh != null) {
        await _storage.write(key: _keyRefreshToken, value: refresh);
      }
    } catch (e) {
      debugPrint('Error saving tokens: $e');
      rethrow;
    }
  }

  static Future<String?> getAccessToken() {
    try {
      return _storage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return Future.value(null);
    }
  }

  static Future<String?> getRefreshToken() {
    try {
      return _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return Future.value(null);
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}
