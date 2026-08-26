import 'package:fcode_pos/services/biometric_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider kiểm tra thiết bị có hỗ trợ sinh trắc học không
final canUseBiometricsProvider = FutureProvider<bool>((ref) async {
  return await BiometricService.instance.isBiometricAvailable();
});

/// Provider tên hiển thị loại sinh trắc học (Face ID, Touch ID, Vân tay...)
final biometricLabelProvider = FutureProvider<String>((ref) async {
  return await BiometricService.instance.getBiometricDisplayName();
});

/// Provider thông tin cấu hình sinh trắc học theo Platform (title, subtitle, icon, buttonLabel)
final biometricInfoProvider = FutureProvider<BiometricInfo>((ref) async {
  return await BiometricService.instance.getBiometricInfo();
});

/// Provider trạng thái bật/tắt khóa app trong cài đặt
final appLockEnabledProvider =
    StateNotifierProvider<AppLockEnabledNotifier, bool>(
  (ref) => AppLockEnabledNotifier(),
);

class AppLockEnabledNotifier extends StateNotifier<bool> {
  AppLockEnabledNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await BiometricService.instance.isAppLockEnabled();
    state = enabled;
  }

  Future<bool> toggle(bool enable) async {
    if (enable) {
      // Khi bật, yêu cầu xác thực thử trước để chắc chắn thiết bị hoạt động
      final success = await BiometricService.instance.authenticate(
        localizedReason: 'Xác thực để kích hoạt khóa ứng dụng',
      );
      if (!success) return false;
    }
    await BiometricService.instance.setAppLockEnabled(enable);
    state = enable;
    return true;
  }
}

/// Provider trạng thái màn hình app đang bị khóa (cần quét Face ID / Passcode)
final isAppLockedProvider = StateNotifierProvider<AppLockStateNotifier, bool>(
  (ref) => AppLockStateNotifier(ref),
);

class AppLockStateNotifier extends StateNotifier<bool> {
  final Ref ref;

  AppLockStateNotifier(this.ref) : super(false) {
    _checkInitialLock();
  }

  Future<void> _checkInitialLock() async {
    final isEnabled = await BiometricService.instance.isAppLockEnabled();
    if (isEnabled) {
      state = true;
    }
  }

  void lock() {
    final isEnabled = ref.read(appLockEnabledProvider);
    if (isEnabled && !state) {
      state = true;
    }
  }

  void unlock() {
    state = false;
  }

  Future<bool> requestUnlock() async {
    final success = await BiometricService.instance.authenticate(
      localizedReason: 'Mở khóa ứng dụng',
    );
    if (success) {
      unlock();
    }
    return success;
  }
}
