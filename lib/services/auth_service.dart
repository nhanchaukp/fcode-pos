import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/storage/secure_storage.dart';
import 'package:fcode_pos/storage/user_prefs.dart';

class AuthService {
  final _api = ApiService().dio;

  Future<User> login(String email, String password) async {
    final res = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = res.data;
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    final user = User.fromJson(data['user']);

    // Lưu token và user
    await SecureStorage.saveTokens(access, refresh);
    await UserPrefs.saveUser(user);

    return user;
  }

  Future<User> getUserInfo() async {
    final res = await _api.get('/user/me');
    final user = User.fromJson(res.data);
    await UserPrefs.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    await UserPrefs.clear();
  }

  Future<PasskeyOptions> getPasskeyOptions() async {
    final res = await _api.get('/auth/passkeys/options');
    return PasskeyOptions.fromJson(res.data);
  }

  Future<User> loginWithPasskey(Map<String, dynamic> passkeyResponse) async {
    final res = await _api.post(
      '/auth/passkeys/authenticate',
      data: {'start_authentication_response': passkeyResponse},
    );

    final data = res.data;
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    final user = User.fromJson(data['user']);

    // Lưu token và user
    await SecureStorage.saveTokens(access, refresh);
    await UserPrefs.saveUser(user);

    return user;
  }
}
