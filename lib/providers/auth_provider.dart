import 'dart:async';
import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/login_result.dart';
import 'package:fcode_pos/services/auth_service.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';
import 'package:fcode_pos/storage/user_prefs.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    checkAuth();
  }

  final _auth = AuthService();

  void _syncUserToCrashlytics(User? user) {
    try {
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.id.toString());
        FirebaseCrashlytics.instance.setCustomKey('user_id', user.id);
        FirebaseCrashlytics.instance.setCustomKey('user_name', user.name);
        FirebaseCrashlytics.instance.setCustomKey('user_email', user.email);
      } else {
        FirebaseCrashlytics.instance.setUserIdentifier('');
        FirebaseCrashlytics.instance.setCustomKey('user_id', 0);
        FirebaseCrashlytics.instance.setCustomKey('user_name', '');
        FirebaseCrashlytics.instance.setCustomKey('user_email', '');
      }
    } catch (_) {}
  }

  /// Khôi phục phiên tức thì từ bộ nhớ máy (0ms latency), sau đó chạy ngầm cập nhật API
  Future<void> checkAuth() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _syncUserToCrashlytics(null);
        state = const AsyncValue.data(null);
        return;
      }

      // 1. Đọc User đã lưu từ bộ nhớ máy -> Cho vào màn hình chính ngay tức thì
      final cachedUser = await UserPrefs.getUser();
      if (cachedUser != null) {
        _syncUserToCrashlytics(cachedUser);
        FirebaseCrashlytics.instance.log(
          'Auth: Instant session restored from cache for user ${cachedUser.id} (${cachedUser.email})',
        );
        state = AsyncValue.data(cachedUser);

        // 2. Chạy ngầm làm mới dữ liệu và đồng bộ FCM Token (không block giao diện)
        unawaited(_syncUserInfoInBackground());
        return;
      }

      // Trường hợp hiếm: có token nhưng mất cached user -> gọi online
      await _syncUserInfoOnline();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.log('Auth: checkAuth fatal error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'checkAuth fatal error',
        fatal: false,
      );
      state = AsyncValue.error(e, stack);
    }
  }

  /// Chạy ngầm làm mới thông tin User (số dư, profile...) mà không làm đơ/chờ màn hình
  Future<void> _syncUserInfoInBackground() async {
    try {
      final response = await _auth.getUserInfo();
      final freshUser = response.data;
      if (freshUser != null) {
        _syncUserToCrashlytics(freshUser);
        state = AsyncValue.data(freshUser);
      }
      unawaited(NotificationService.instance.syncTokenWithServer());
    } on ApiException catch (e) {
      // Chỉ đăng xuất khi thực sự nhận mã 401 Unauthorized từ máy chủ
      if (e.statusCode == 401) {
        FirebaseCrashlytics.instance.log(
          'Auth: Background sync received 401. Token expired, logging out.',
        );
        await logout();
      } else {
        FirebaseCrashlytics.instance.log(
          'Auth: Background sync non-critical API response: ${e.statusCode} ${e.message}',
        );
      }
    } catch (e) {
      // Lỗi mạng bình thường khi đang mở app -> giữ nguyên phiên làm việc của user
      FirebaseCrashlytics.instance.log('Auth: Background sync network issue: $e');
    }
  }

  /// Gọi online lấy thông tin User khi máy chưa có cache
  Future<void> _syncUserInfoOnline() async {
    try {
      final response = await _auth.getUserInfo();
      final user = response.data;
      if (user != null) {
        _syncUserToCrashlytics(user);
        FirebaseCrashlytics.instance.log(
          'Auth: Session restored online for user ${user.id} (${user.email})',
        );
        unawaited(NotificationService.instance.syncTokenWithServer());
        state = AsyncValue.data(user);
      } else {
        _syncUserToCrashlytics(null);
        state = const AsyncValue.data(null);
      }
    } on ApiException catch (e, stack) {
      if (e.statusCode == 401) {
        FirebaseCrashlytics.instance.log(
          'Auth: Session expired (401 Unauthorized). Clearing credentials.',
        );
        await SecureStorage.clear();
        await UserPrefs.clear();
        _syncUserToCrashlytics(null);
        state = const AsyncValue.data(null);
        return;
      }

      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'checkAuth online sync failed',
        fatal: false,
      );
      state = AsyncValue.error(e, stack);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'checkAuth online sync unexpected error',
        fatal: false,
      );
      state = AsyncValue.error(e, stack);
    }
  }

  Future<LoginResult> login(String email, String password) async {
    try {
      FirebaseCrashlytics.instance.log('Auth: Attempting login for $email');
      final result = await _auth.login(email, password);
      if (!result.requiresTwoFactor && result.user != null) {
        final user = result.user!;
        _syncUserToCrashlytics(user);
        FirebaseCrashlytics.instance.log(
          'Auth: Login successful for user ${user.id} (${user.email})',
        );
        state = AsyncValue.data(user);
        unawaited(NotificationService.instance.syncTokenWithServer());
      } else if (result.requiresTwoFactor) {
        FirebaseCrashlytics.instance.log('Auth: Login requires 2FA for $email');
      }
      return result;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.log('Auth: Login failed for $email - Error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Login failed for $email',
        fatal: false,
      );
      rethrow;
    }
  }

  Future<User?> verifyTwoFactor({
    String? code,
    String? recoveryCode,
  }) async {
    try {
      FirebaseCrashlytics.instance.log('Auth: Attempting 2FA verification');
      final user = await _auth.verifyTwoFactor(
        code: code,
        recoveryCode: recoveryCode,
      );
      _syncUserToCrashlytics(user);
      FirebaseCrashlytics.instance.log(
        'Auth: 2FA verified successfully for user ${user.id} (${user.email})',
      );
      state = AsyncValue.data(user);
      unawaited(NotificationService.instance.syncTokenWithServer());
      return user;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.log('Auth: 2FA verification failed: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: '2FA verification failed',
        fatal: false,
      );
      rethrow;
    }
  }

  Future<void> cancelTwoFactorChallenge() async {
    FirebaseCrashlytics.instance.log('Auth: 2FA challenge cancelled by user');
    await _auth.clearAuthSession();
  }

  Future<void> logout() async {
    try {
      final currentUser = state.asData?.value;
      if (currentUser != null) {
        FirebaseCrashlytics.instance.log(
          'Auth: User logging out: ${currentUser.id} (${currentUser.email})',
        );
      } else {
        FirebaseCrashlytics.instance.log('Auth: User logging out');
      }
      await _auth.logout();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.log('Auth: Logout encountered error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Logout error',
        fatal: false,
      );
    } finally {
      _syncUserToCrashlytics(null);
      state = const AsyncValue.data(null);
    }
  }
}