import 'dart:convert';

import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatGptSessionStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const _key = 'chatgpt_sessions';

  static Future<List<ChatGptSession>> loadAll() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatGptSession.fromStorageJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ChatGptStorage] loadAll error: $e');
      return [];
    }
  }

  static Future<void> save(ChatGptSession session) async {
    try {
      final sessions = await loadAll();
      final idx = sessions.indexWhere((s) => s.email == session.email);
      if (idx >= 0) {
        sessions[idx] = session;
      } else {
        sessions.add(session);
      }
      await _write(sessions);
    } catch (e) {
      debugPrint('[ChatGptStorage] save error: $e');
      rethrow;
    }
  }

  static Future<void> delete(String email) async {
    try {
      final sessions = await loadAll();
      sessions.removeWhere((s) => s.email == email);
      await _write(sessions);
    } catch (e) {
      debugPrint('[ChatGptStorage] delete error: $e');
      rethrow;
    }
  }

  static Future<ChatGptSession?> findByEmail(String email) async {
    final sessions = await loadAll();
    try {
      return sessions.firstWhere((s) => s.email == email);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(List<ChatGptSession> sessions) async {
    final json = jsonEncode(sessions.map((s) => s.toStorageJson()).toList());
    await _storage.write(key: _key, value: json);
  }
}
