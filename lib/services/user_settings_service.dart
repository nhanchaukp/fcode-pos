import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý User Settings (cài đặt cá nhân & âm thanh thông báo)
/// theo tài liệu `docs/ApiUserSettingsFlutter.md`
///
/// Các Endpoint:
/// - GET `/api/user/my-settings`: Lấy cài đặt cá nhân của User hiện tại
/// - PUT `/api/user/my-settings`: Cập nhật cài đặt cá nhân của User hiện tại
class UserSettingsService {
  UserSettingsService() : _api = ApiService();

  final ApiService _api;

  /// Lấy cấu hình âm thanh thông báo của User hiện tại
  ///
  /// Response: `{"success": true, "data": {"notification_sound": "anime_aah"}}`
  Future<String> getMyNotificationSound() async {
    try {
      final response = await _api.get<dynamic>('/user/my-settings');
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final sound = data['notification_sound'] ??
              (data['settings'] is Map
                  ? data['settings']['notification_sound']
                  : null);
          if (sound != null && sound is String && sound.isNotEmpty) {
            return sound;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy User Settings từ Server: $e');
      }
    }
    return 'default';
  }

  /// Cập nhật âm thanh thông báo của User hiện tại lên Server
  ///
  /// Endpoint: `PUT /api/user/my-settings`
  /// Body: `{"notification_sound": "anime_aah"}`
  Future<bool> updateMyNotificationSound(String soundName) async {
    try {
      final response = await _api.put<dynamic>(
        '/user/my-settings',
        data: {
          'notification_sound': soundName,
        },
      );
      return response.success;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi cập nhật User Settings lên Server: $e');
      }
      return false;
    }
  }

  /// Lấy toàn bộ thông tin User Settings
  Future<ApiResponse<dynamic>> getMySettings() {
    return _api.get<dynamic>('/user/my-settings');
  }

  /// Cập nhật User Settings tổng quát
  Future<ApiResponse<dynamic>> updateMySettings(Map<String, dynamic> settings) {
    return _api.put<dynamic>(
      '/user/my-settings',
      data: settings,
    );
  }
}
