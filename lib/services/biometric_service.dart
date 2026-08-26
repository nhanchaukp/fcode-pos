import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._internal();
  static final BiometricService instance = BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyAppLockEnabled = 'app_lock_biometric_enabled';

  /// Kiểm tra thiết bị có phần cứng và hỗ trợ sinh trắc học không
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Lấy danh sách các loại sinh trắc học đã cài đặt trên máy
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Lấy tên hiển thị thân thiện tùy theo thiết bị (Face ID, Touch ID, Vân tay...)
  Future<String> getBiometricDisplayName() async {
    if (kIsWeb) return 'Sinh trắc học';
    try {
      final biometrics = await getAvailableBiometrics();
      if (Platform.isIOS || Platform.isMacOS) {
        if (biometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        }
        return 'Face ID / Touch ID';
      } else if (Platform.isAndroid) {
        if (biometrics.contains(BiometricType.fingerprint) &&
            biometrics.contains(BiometricType.face)) {
          return 'Vân tay / Khuôn mặt';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Vân tay';
        } else if (biometrics.contains(BiometricType.face)) {
          return 'Nhận diện khuôn mặt';
        }
      }
    } catch (_) {}
    return 'Face ID / Vân tay';
  }

  /// Thực hiện quét sinh trắc học hoặc mật mã máy (Device Passcode / PIN fallback)
  Future<bool> authenticate({
    String localizedReason = 'Xác thực để mở khóa ứng dụng',
  }) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false, // Cho phép fallback sang Passcode/PIN của điện thoại
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric authentication PlatformException: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Kiểm tra người dùng có bật tính năng khóa app trong cài đặt không
  Future<bool> isAppLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAppLockEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Bật / Tắt tính năng khóa app
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, enabled);
  }
}
