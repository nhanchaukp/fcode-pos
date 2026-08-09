import 'package:fcode_pos/services/notification_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider quản lý trạng thái bật/tắt thông báo của ứng dụng
final notificationEnabledProvider =
    StateNotifierProvider<NotificationEnabledNotifier, bool>(
  (ref) => NotificationEnabledNotifier(),
);

class NotificationEnabledNotifier extends StateNotifier<bool> {
  NotificationEnabledNotifier() : super(true) {
    _loadNotificationSetting();
  }

  static const _key = 'notifications_enabled';

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null && stored != state) {
      state = stored;
      NotificationService.instance.setNotificationEnabled(stored);
    }
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    if (enabled == state) return;
    state = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);

    await NotificationService.instance.setNotificationEnabled(enabled);
  }

  Future<void> toggleNotification() {
    return setNotificationEnabled(!state);
  }
}
