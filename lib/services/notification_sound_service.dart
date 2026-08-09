import 'package:audioplayers/audioplayers.dart';
import 'package:fcode_pos/models/notification_sound_item.dart';
import 'package:fcode_pos/services/user_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSoundService {
  NotificationSoundService._internal();
  static final NotificationSoundService instance =
      NotificationSoundService._internal();

  static const String _prefKey = 'selected_notification_sound_id';
  final AudioPlayer _audioPlayer = AudioPlayer();

  NotificationSoundItem _currentSound =
      NotificationSoundItem.availableSounds.first;

  NotificationSoundItem get currentSound => _currentSound;

  /// Khởi tạo và đọc nhạc chuông đã lưu từ SharedPreferences + đồng bộ từ Server
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey) ?? 'default';
      _currentSound = NotificationSoundItem.findById(savedId);

      // Đồng bộ ngầm với Server
      syncWithServer();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading saved notification sound: $e');
      }
    }
  }

  /// Đồng bộ nhạc chuông từ Server API (GET /api/user/my-settings)
  Future<void> syncWithServer() async {
    try {
      final serverSound = await UserSettingsService().getMyNotificationSound();
      if (serverSound.isNotEmpty) {
        final soundItem = NotificationSoundItem.findById(serverSound);
        _currentSound = soundItem;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, soundItem.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notification sound with server: $e');
      }
    }
  }

  /// Phát nghe thử một file nhạc chuông
  Future<void> previewSound(NotificationSoundItem item) async {
    try {
      await _audioPlayer.stop();
      if (item.id == 'default' || item.assetPath.isEmpty) return;
      await _audioPlayer.play(AssetSource(item.assetPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error previewing sound: $e');
      }
    }
  }

  /// Dừng phát âm thanh preview
  Future<void> stopPreview() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Chọn và lưu nhạc chuông mới vào SharedPreferences + Cập nhật lên Server
  Future<void> setSelectedSound(NotificationSoundItem item) async {
    _currentSound = item;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, item.id);

      // Đẩy setting lên Server API (PUT /api/user/my-settings)
      await UserSettingsService().updateMyNotificationSound(item.androidSoundName);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification sound: $e');
      }
    }
  }

  /// Tạo AndroidNotificationDetails dựa trên nhạc chuông đã chọn
  AndroidNotificationDetails buildAndroidNotificationDetails() {
    final isDefault = _currentSound.id == 'default';
    return AndroidNotificationDetails(
      isDefault
          ? 'pos_orders_channel'
          : 'pos_orders_channel_${_currentSound.androidSoundName}',
      'Đơn hàng POS Admin',
      channelDescription:
          'Kênh nhận thông báo đơn hàng mới và cập nhật trạng thái.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: isDefault
          ? null
          : RawResourceAndroidNotificationSound(_currentSound.androidSoundName),
      playSound: true,
    );
  }

  /// Tạo DarwinNotificationDetails (iOS) dựa trên nhạc chuông đã chọn
  DarwinNotificationDetails buildIosNotificationDetails() {
    final isDefault = _currentSound.id == 'default';
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: isDefault ? null : _currentSound.fileName,
    );
  }
}
