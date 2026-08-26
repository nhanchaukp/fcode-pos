import 'dart:async';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/login_result.dart';
import 'package:fcode_pos/services/auth_service.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';
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

  Future<void> checkAuth() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null) {
        _syncUserToCrashlytics(null);
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _auth.getUserInfo();
      final user = response.data;
      state = AsyncValue.data(user);
      if (user != null) {
        _syncUserToCrashlytics(user);
        FirebaseCrashlytics.instance.log(
          'Auth: Session restored for user ${user.id} (${user.email})',
        );
        unawaited(NotificationService.instance.syncTokenWithServer());
      } else {
        _syncUserToCrashlytics(null);
      }
    } catch (e, stack) {
      _syncUserToCrashlytics(null);
      FirebaseCrashlytics.instance.log('Auth: checkAuth failed: $e');
      await SecureStorage.clear();
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