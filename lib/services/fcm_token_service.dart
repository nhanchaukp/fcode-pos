import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/services/api_service.dart';

/// Service quản lý API FCM Device Token cho máy POS Admin theo chuẩn ApiFcmNotificationFlutter.md
///
/// Các endpoint hỗ trợ:
/// - POST `/api/fcm-token`: Đăng ký / cập nhật FCM Device Token
/// - DELETE `/api/fcm-token`: Xóa FCM Device Token khi đăng xuất
class FcmTokenService {
  FcmTokenService() : _api = ApiService();

  final ApiService _api;

  /// Tự động xác định loại thiết bị phù hợp (pos_android, pos_ios, pos_web, pos_desktop, pos)
  static String resolveDeviceType() {
    if (kIsWeb) return 'pos_web';
    if (Platform.isAndroid) return 'pos_android';
    if (Platform.isIOS) return 'pos_ios';
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'pos_desktop';
    }
    return 'pos';
  }

  /// Đăng ký / cập nhật FCM Device Token của máy POS Admin
  ///
  /// Endpoint: `POST /api/fcm-token`
  /// [fcmToken] - FCM Device Token thu thập được từ Firebase Messaging (chuỗi max 500 ký tự)
  /// [deviceType] - Loại thiết bị ('pos_android', 'pos_ios', 'pos_web', 'pos') (mặc định tự nhận diện)
  /// [deviceName] - Tên thiết bị (tùy chọn)
  Future<ApiResponse<dynamic>> registerToken(
    String fcmToken, {
    String? deviceType,
    String? deviceName,
  }) {
    final resolvedDeviceType = deviceType ?? resolveDeviceType();

    final data = <String, dynamic>{
      'token': fcmToken,
      'fcm_token': fcmToken,
      'device_type': resolvedDeviceType,
      'device_name': ?deviceName,
    };

    return _api.post<dynamic>(
      '/fcm-token',
      data: data,
    );
  }

  /// Alias cho [registerToken]
  Future<ApiResponse<dynamic>> registerFcmToken(
    String fcmToken, {
    String? deviceType,
    String? deviceName,
  }) =>
      registerToken(fcmToken, deviceType: deviceType, deviceName: deviceName);

  /// Xóa FCM Device Token khi đăng xuất
  ///
  /// Endpoint: `DELETE /api/fcm-token`
  /// [fcmToken] - FCM Device Token cần xóa
  Future<ApiResponse<dynamic>> deleteToken({String? fcmToken}) {
    return _api.delete<dynamic>(
      '/fcm-token',
      data: fcmToken != null && fcmToken.isNotEmpty
          ? {
              'token': fcmToken,
              'fcm_token': fcmToken,
            }
          : null,
    );
  }

  /// Alias cho [deleteToken]
  Future<ApiResponse<dynamic>> deleteFcmToken({String? fcmToken}) =>
      deleteToken(fcmToken: fcmToken);
}
