import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/login_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fcode_pos/services/auth_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    checkAuth();
  }

  final _auth = AuthService();

  Future<void> checkAuth() async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _auth.getUserInfo();
      state = AsyncValue.data(response.data);
    } catch (e) {
      await SecureStorage.clear();
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<LoginResult> login(String email, String password) async {
    final result = await _auth.login(email, password);
    if (!result.requiresTwoFactor && result.user != null) {
      state = AsyncValue.data(result.user);
    }
    return result;
  }

  Future<User?> verifyTwoFactor({
    String? code,
    String? recoveryCode,
  }) async {
    final user = await _auth.verifyTwoFactor(
      code: code,
      recoveryCode: recoveryCode,
    );
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> cancelTwoFactorChallenge() async {
    await _auth.clearAuthSession();
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncValue.data(null);
  }
}