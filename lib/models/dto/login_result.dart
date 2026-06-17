import 'package:fcode_pos/models.dart';

class LoginResult {
  final bool requiresTwoFactor;
  final User? user;

  const LoginResult._({
    required this.requiresTwoFactor,
    this.user,
  });

  factory LoginResult.requiresTwoFactor() {
    return const LoginResult._(requiresTwoFactor: true);
  }

  factory LoginResult.success(User user) {
    return LoginResult._(requiresTwoFactor: false, user: user);
  }
}