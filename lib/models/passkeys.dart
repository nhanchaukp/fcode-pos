part of '../models.dart';

class PasskeyOptions implements Model {
  final String challenge;

  final String rpId;

  final List<String>? allowCredentials;

  final String? userVerification;

  PasskeyOptions({
    required this.challenge,
    required this.rpId,
    this.allowCredentials,
    this.userVerification,
  });

  factory PasskeyOptions.fromJson(Map<String, dynamic> map) {
    return PasskeyOptions(
      challenge: map['challenge'].toString(),
      rpId: map['rpId'].toString(),
      allowCredentials: map['allowCredentials'] != null
          ? List<String>.from(map['allowCredentials'] as List)
          : null,
      userVerification: map['userVerification']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'challenge': challenge,
      'rpId': rpId,
      'allowCredentials': allowCredentials,
      'userVerification': userVerification,
    };
  }
}
