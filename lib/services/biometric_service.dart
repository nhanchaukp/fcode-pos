import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricInfo {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;

  const BiometricInfo({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
  });
}

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

  /// Lấy thông tin hiển thị chuẩn theo từng nền tảng (iOS vs Android vs Web)
  Future<BiometricInfo> getBiometricInfo() async {
    if (kIsWeb) {
      return const BiometricInfo(
        title: 'Khóa ứng dụng',
        subtitle: 'Yêu cầu mật khẩu khi mở ứng dụng',
        buttonLabel: 'Mở khóa ứng dụng',
        icon: Icons.lock_outline,
      );
    }

    try {
      final biometrics = await getAvailableBiometrics();
      if (Platform.isIOS || Platform.isMacOS) {
        if (biometrics.contains(BiometricType.face)) {
          return const BiometricInfo(
            title: 'Mở khóa bằng Face ID',
            subtitle: 'Yêu cầu Face ID hoặc mật mã thiết bị khi mở ứng dụng',
            buttonLabel: 'Mở khóa bằng Face ID',
            icon: Icons.face_rounded,
          );
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return const BiometricInfo(
            title: 'Mở khóa bằng Touch ID',
            subtitle: 'Yêu cầu Touch ID hoặc mật mã thiết bị khi mở ứng dụng',
            buttonLabel: 'Mở khóa bằng Touch ID',
            icon: Icons.fingerprint_rounded,
          );
        }
        return const BiometricInfo(
          title: 'Mở khóa bằng Face ID',
          subtitle: 'Yêu cầu Face ID hoặc mật mã thiết bị khi mở ứng dụng',
          buttonLabel: 'Mở khóa bằng Face ID',
          icon: Icons.face_rounded,
        );
      } else if (Platform.isAndroid) {
        if (biometrics.contains(BiometricType.fingerprint) &&
            biometrics.contains(BiometricType.face)) {
          return const BiometricInfo(
            title: 'Mở khóa bằng sinh trắc học',
            subtitle:
                'Yêu cầu vân tay, khuôn mặt hoặc mã PIN / hình mở khóa khi mở ứng dụng',
            buttonLabel: 'Mở khóa bằng sinh trắc học',
            icon: Icons.fingerprint_rounded,
          );
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return const BiometricInfo(
            title: 'Mở khóa bằng vân tay',
            subtitle:
                'Yêu cầu vân tay hoặc mã PIN / hình mở khóa khi mở ứng dụng',
            buttonLabel: 'Mở khóa bằng vân tay',
            icon: Icons.fingerprint_rounded,
          );
        } else if (biometrics.contains(BiometricType.face)) {
          return const BiometricInfo(
            title: 'Mở khóa bằng nhận diện khuôn mặt',
            subtitle:
                'Yêu cầu nhận diện khuôn mặt hoặc mã PIN / hình mở khóa khi mở ứng dụng',
            buttonLabel: 'Mở khóa bằng khuôn mặt',
            icon: Icons.face_unlock_rounded,
          );
        }
        return const BiometricInfo(
          title: 'Mở khóa bằng vân tay',
          subtitle:
              'Yêu cầu vân tay hoặc mã PIN / hình mở khóa khi mở ứng dụng',
          buttonLabel: 'Mở khóa bằng vân tay',
          icon: Icons.fingerprint_rounded,
        );
      }
    } catch (_) {}

    return const BiometricInfo(
      title: 'Mở khóa bằng sinh trắc học',
      subtitle: 'Yêu cầu sinh trắc học hoặc mật mã máy khi mở ứng dụng',
      buttonLabel: 'Mở khóa ứng dụng',
      icon: Icons.fingerprint_rounded,
    );
  }

  /// Lấy tên hiển thị thân thiện tùy theo thiết bị (Face ID, Touch ID, Vân tay...)
  Future<String> getBiometricDisplayName() async {
    final info = await getBiometricInfo();
    return info.title.replaceFirst('Mở khóa bằng ', '');
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
