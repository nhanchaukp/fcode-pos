import 'package:fcode_pos/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
// import 'package:passkeys/authenticator.dart';
// import 'package:passkeys/types.dart';
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

  // Future<User?> loginWithPasskey() async {
  //   // state = const AsyncValue.loading();
  //   try {
  //     final passkeyAuth = PasskeyAuthenticator();

  //     final passkeyOptionsResponse = await _auth.getPasskeyOptions();
  //     final passkeyOptions = passkeyOptionsResponse.data;
  //     if (passkeyOptions == null) {
  //       throw StateError('Không thể lấy thông tin Passkey.');
  //     }

  //     // Remove padding from challenge (passkeys package requires Base64URL without padding)
  //     final challengeWithoutPadding = passkeyOptions.challenge.replaceAll(
  //       '=',
  //       '',
  //     );

  //     // Authenticate with platform passkeys (iCloud Keychain, Android Credential Manager)
  //     final authResponse = await passkeyAuth.authenticate(
  //       AuthenticateRequestType(
  //         challenge: challengeWithoutPadding,
  //         relyingPartyId: passkeyOptions.rpId,
  //         timeout: 300000, // 5 minutes
  //         userVerification: passkeyOptions.userVerification ?? 'preferred',
  //         mediation: MediationType.Optional,
  //         preferImmediatelyAvailableCredentials: true,
  //         allowCredentials: passkeyOptions.allowCredentials
  //             ?.map(
  //               (id) =>
  //                   CredentialType(type: 'public-key', id: id, transports: []),
  //             )
  //             .toList(),
  //       ),
  //     );

  //     // Convert response to format expected by backend
  //     final passkeyResponse = {
  //       'id': authResponse.id,
  //       'rawId': authResponse.rawId,
  //       'response': {
  //         'clientDataJSON': authResponse.clientDataJSON,
  //         'authenticatorData': authResponse.authenticatorData,
  //         'signature': authResponse.signature,
  //         'userHandle': authResponse.userHandle,
  //       },
  //       'type': 'public-key',
  //     };

  //     final response = await _auth.loginWithPasskey(passkeyResponse);
  //     final user = response.data;
  //     state = AsyncValue.data(user);
  //     return user;
  //   } on PasskeyAuthCancelledException {
  //     state = AsyncValue.error('Đăng nhập đã bị hủy', StackTrace.current);
  //     rethrow;
  //   } on NoCredentialsAvailableException {
  //     state = AsyncValue.error(
  //       'Không tìm thấy Passkey. Vui lòng đăng ký Passkey trước.',
  //       StackTrace.current,
  //     );
  //     rethrow;
  //   } on DomainNotAssociatedException catch (e) {
  //     state = AsyncValue.error(
  //       'Domain không được liên kết: ${e.message}',
  //       StackTrace.current,
  //     );
  //     rethrow;
  //   } catch (e) {
  //     state = AsyncValue.error(e, StackTrace.current);
  //     rethrow;
  //   }
  // }
}
