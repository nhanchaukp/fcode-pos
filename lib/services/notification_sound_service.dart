import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:fcode_pos/models/notification_sound_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSoundService {
  NotificationSoundService._internal();
  static final NotificationSoundService instance =
      NotificationSoundService._internal();

  static const String _prefKey = 'selected_notification_sound_id';
  static const MethodChannel _appGroupChannel = MethodChannel('fcode/app_group');
  final AudioPlayer _audioPlayer = AudioPlayer();

  NotificationSoundItem _currentSound =
      NotificationSoundItem.availableSounds.first;

  NotificationSoundItem get currentSound => _currentSound;

  /// Đồng bộ tên file nhạc chuông sang App Group UserDefaults dành cho iOS Extension
  Future<void> _syncToIosAppGroup(String fileName) async {
    if (!Platform.isIOS) return;
    try {
      await _appGroupChannel.invokeMethod('setNotificationSound', {
        'fileName': fileName,
      });
      if (kDebugMode) {
        print('Synced sound "$fileName" to iOS App Group');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing sound to iOS App Group: $e');
      }
    }
  }

  /// Khởi tạo và đọc nhạc chuông đã lưu từ SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey) ?? 'default';
      _currentSound = NotificationSoundItem.findById(savedId);

      await _syncToIosAppGroup(_currentSound.fileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error reading saved notification sound: $e');
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

  /// Chọn và lưu nhạc chuông mới vào SharedPreferences cục bộ
  Future<void> setSelectedSound(NotificationSoundItem item) async {
    _currentSound = item;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, item.id);

      await _syncToIosAppGroup(item.fileName);
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

