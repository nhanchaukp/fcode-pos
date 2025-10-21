part of '../models.dart';

/// LoginResponse
class LoginResponse implements Model {
  /// LoginResponse access token.
  final String accessToken;

  /// LoginResponse token type.
  final String tokenType;

  final User user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> map) {
    return LoginResponse(
      accessToken: map['access_token']?.toString() ?? '',
      tokenType: map['token_type']?.toString() ?? '',
      user: User.fromJson(map['user'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toMap(),
    };
  }
}
