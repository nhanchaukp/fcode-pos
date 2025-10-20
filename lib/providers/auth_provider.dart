import 'package:credential_manager/credential_manager.dart' as cred;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/utils/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
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

      final user = await _auth.getUserInfo();
      state = AsyncValue.data(user);
    } catch (e) {
      await SecureStorage.clear();
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<User?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.login(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      debugPrint('Login error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncValue.data(null);
  }

  Future<User?> loginWithPasskey() async {
    // state = const AsyncValue.loading();
    try {
      final passkeyOptions = await _auth.getPasskeyOptions();

      final credResponse = await AppInitializer.credentialManager
          .getCredentials(
            passKeyOption: cred.CredentialLoginOptions(
              challenge: passkeyOptions.challenge,
              rpId: passkeyOptions.rpId,
              userVerification: 'preferred',
            ),
          );

      // final passkeyAuthenticator = PasskeyAuthenticator();

      // final authRequest = AuthenticateRequestType(
      //     challenge: passkeyOptions.challenge,
      //     relyingPartyId: passkeyOptions.rpId,
      //     mediation: MediationType.Optional,
      //     timeout: 30000,
      //     preferImmediatelyAvailableCredentials: true);

      // final platformRes = await passkeyAuthenticator.authenticate(authRequest);

      final user = await _auth.loginWithPasskey(
        credResponse.publicKeyCredential?.toJson() ?? {},
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
