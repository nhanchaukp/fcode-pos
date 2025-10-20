part of '../models.dart';

class PasskeyOptions implements Model {
  final String challenge;

  final String rpId;

  final List<String>? allowCredentials;

  PasskeyOptions({
    required this.challenge,
    required this.rpId,
    this.allowCredentials,
  });

  factory PasskeyOptions.fromJson(Map<String, dynamic> map) {
    return PasskeyOptions(
      challenge: map['challenge'],
      rpId: map['rpId'],
      allowCredentials: map['allowCredentials'] != null
          ? List<String>.from(map['allowCredentials'] as List)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'challenge': challenge,
      'rpId': rpId,
      'allowCredentials': allowCredentials,
    };
  }
}
