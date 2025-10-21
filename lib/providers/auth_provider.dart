import 'dart:convert';
import 'package:fcode_pos/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:webauthn/webauthn.dart';
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
        state = const AsyncValue.data(null); // chưa login
        return;
      }

      final response = await _auth.getUserInfo();
      state = AsyncValue.data(response.data);
    } catch (e) {
      await SecureStorage.clear();
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<User?> login(String email, String password) async {
    final response = await _auth.login(email, password);
    final user = response.data;
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncValue.data(null);
  }

  Future<User?> loginWithPasskey() async {
    // state = const AsyncValue.loading();
    try {
      final Authenticator authenticator = Authenticator(true, false);

      final passkeyOptionsResponse = await _auth.getPasskeyOptions();
      final passkeyOptions = passkeyOptionsResponse.data;
      if (passkeyOptions == null) {
        throw StateError('Không thể lấy thông tin Passkey.');
      }
      final Assertion assertion = await authenticator.getAssertion(
        GetAssertionOptions(
          rpId: passkeyOptions.rpId,
          clientDataHash: base64Url.decode(passkeyOptions.challenge),
          requireUserPresence: true,
          requireUserVerification: false,
        ),
      );

      final response = await _auth.loginWithPasskey(assertion.toJson());
      final user = response.data;
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
