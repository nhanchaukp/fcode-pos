import 'dart:convert';

class ChatGptSession {
  final String email;
  final String userId;
  final String name;
  final String? image;

  /// Raw JSON string từ chatgpt.com/api/auth/session.
  /// Chứa access_token, expires, user, v.v.
  final String sessionJson;

  final DateTime savedAt;

  const ChatGptSession({
    required this.email,
    required this.userId,
    required this.name,
    this.image,
    required this.sessionJson,
    required this.savedAt,
  });

  // ── Computed từ sessionJson ─────────────────────────────────────────────────

  String? get accessToken {
    try {
      final m = jsonDecode(sessionJson) as Map<String, dynamic>;
      return m['accessToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? get expires {
    try {
      final m = jsonDecode(sessionJson) as Map<String, dynamic>;
      return m['expires'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool get isExpired {
    final exp = expires;
    if (exp == null) return false;
    final date = DateTime.tryParse(exp);
    if (date == null) return false;
    return DateTime.now().isAfter(date);
  }

  // ── Factories ───────────────────────────────────────────────────────────────

  /// Tạo từ raw session JSON string + user info từ /v1/me.
  factory ChatGptSession.fromSessionAndUser({
    required String rawSessionJson,
    required Map<String, dynamic> userInfo,
  }) {
    return ChatGptSession(
      email: userInfo['email'] as String? ?? '',
      userId: userInfo['id'] as String? ?? '',
      name: userInfo['name'] as String? ?? '',
      image: userInfo['picture'] as String?,
      sessionJson: rawSessionJson,
      savedAt: DateTime.now(),
    );
  }

  factory ChatGptSession.fromStorageJson(Map<String, dynamic> json) {
    return ChatGptSession(
      email: json['email'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      sessionJson: json['sessionJson'] as String? ?? '{}',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toStorageJson() => {
        'email': email,
        'userId': userId,
        'name': name,
        'image': image,
        'sessionJson': sessionJson,
        'savedAt': savedAt.toIso8601String(),
      };

  ChatGptSession copyWith({
    String? name,
    String? image,
    String? sessionJson,
    DateTime? savedAt,
  }) =>
      ChatGptSession(
        email: email,
        userId: userId,
        name: name ?? this.name,
        image: image ?? this.image,
        sessionJson: sessionJson ?? this.sessionJson,
        savedAt: savedAt ?? this.savedAt,
      );
}
