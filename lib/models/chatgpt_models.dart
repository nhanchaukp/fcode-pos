import 'dart:convert';

class ChatGptSession {
  final String email;
  final String userId;
  final String name;
  final String? image;
  final String? planType;
  final String? expires;
  final String sessionJson;
  final String cookiesJson;
  final DateTime savedAt;

  const ChatGptSession({
    required this.email,
    required this.userId,
    required this.name,
    this.image,
    this.planType,
    this.expires,
    required this.sessionJson,
    required this.cookiesJson,
    required this.savedAt,
  });

  factory ChatGptSession.fromSessionApiJson({
    required Map<String, dynamic> json,
    required String cookiesJson,
  }) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final account = json['account'] as Map<String, dynamic>? ?? {};
    return ChatGptSession(
      email: user['email'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      name: user['name'] as String? ?? '',
      image: (user['picture'] ?? user['image']) as String?,
      planType: account['planType'] as String?,
      expires: json['expires'] as String?,
      sessionJson: jsonEncode(json),
      cookiesJson: cookiesJson,
      savedAt: DateTime.now(),
    );
  }

  factory ChatGptSession.fromStorageJson(Map<String, dynamic> json) {
    return ChatGptSession(
      email: json['email'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      planType: json['planType'] as String?,
      expires: json['expires'] as String?,
      sessionJson: json['sessionJson'] as String? ?? '{}',
      cookiesJson: json['cookiesJson'] as String? ?? '[]',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'email': email,
      'userId': userId,
      'name': name,
      'image': image,
      'planType': planType,
      'expires': expires,
      'sessionJson': sessionJson,
      'cookiesJson': cookiesJson,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  ChatGptSession copyWith({
    String? name,
    String? image,
    String? planType,
    String? expires,
    String? sessionJson,
    String? cookiesJson,
    DateTime? savedAt,
  }) {
    return ChatGptSession(
      email: email,
      userId: userId,
      name: name ?? this.name,
      image: image ?? this.image,
      planType: planType ?? this.planType,
      expires: expires ?? this.expires,
      sessionJson: sessionJson ?? this.sessionJson,
      cookiesJson: cookiesJson ?? this.cookiesJson,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  bool get isExpired {
    if (expires == null) return false;
    final expireDate = DateTime.tryParse(expires!);
    if (expireDate == null) return false;
    return DateTime.now().isAfter(expireDate);
  }

  bool get isPro => planType != null && planType != 'free';
}
