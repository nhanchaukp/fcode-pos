import 'dart:convert';
import 'dart:io';

import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class ChatGptSessionService {
  static const _sessionUrl = 'https://chatgpt.com/api/auth/session';
  static const _chatgptHost = 'https://chatgpt.com';
  static const _meUrl = 'https://api.openai.com/v1/me';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Capture session từ InAppWebView sau khi user đã đăng nhập.
  /// Reads cookies → fetches session JSON → extracts access_token → calls /v1/me.
  Future<ChatGptSession> captureSession() async {
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri(_chatgptHost));

    if (cookies.isEmpty) {
      throw Exception('Không tìm thấy cookies. Vui lòng đăng nhập trước.');
    }

    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
    final rawSessionJson = await _fetchSessionJson(cookieHeader);
    return _buildSession(rawSessionJson);
  }

  /// Tạo session từ raw JSON string do user paste vào thủ công.
  /// JSON phải chứa `accessToken` để gọi /v1/me.
  Future<ChatGptSession> createFromJson(String rawJson) async {
    // Validate JSON
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('JSON không hợp lệ.');
    }

    final token = parsed['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy trường "accessToken" trong JSON.');
    }

    final userInfo = await fetchUserInfo(token);
    return ChatGptSession.fromSessionAndUser(
      rawSessionJson: rawJson,
      userInfo: userInfo,
    );
  }

  /// Gọi GET https://api.openai.com/v1/me với access token.
  Future<Map<String, dynamic>> fetchUserInfo(String accessToken) async {
    debugPrint('[ChatGptService] fetching /v1/me ...');
    final response = await http.get(
      Uri.parse(_meUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('[ChatGptService] /v1/me status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
          'Không thể lấy thông tin người dùng (HTTP ${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Xóa toàn bộ cookies và web storage để đảm bảo browser sạch khi thêm mới.
  Future<void> clearAllWebViewData() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();

    if (Platform.isAndroid) {
      await WebStorageManager.instance().deleteAllData();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await WebStorageManager.instance().removeDataModifiedSince(
        dataTypes: {
          WebsiteDataType.WKWebsiteDataTypeCookies,
          WebsiteDataType.WKWebsiteDataTypeLocalStorage,
          WebsiteDataType.WKWebsiteDataTypeSessionStorage,
          WebsiteDataType.WKWebsiteDataTypeIndexedDBDatabases,
          WebsiteDataType.WKWebsiteDataTypeDiskCache,
          WebsiteDataType.WKWebsiteDataTypeMemoryCache,
        },
        date: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    debugPrint('[ChatGptService] cleared all WebView data');
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<String> _fetchSessionJson(String cookieHeader) async {
    debugPrint('[ChatGptService] fetching session...');
    final response = await http.get(
      Uri.parse(_sessionUrl),
      headers: {
        'Cookie': cookieHeader,
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        'Accept': 'application/json',
        'Referer': 'https://chatgpt.com/',
      },
    );

    debugPrint('[ChatGptService] session status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
          'Không thể lấy session (HTTP ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['accessToken'] == null) {
      throw Exception('Chưa đăng nhập hoặc session đã hết hạn.');
    }

    return response.body;
  }

  Future<ChatGptSession> _buildSession(String rawSessionJson) async {
    final sessionMap = jsonDecode(rawSessionJson) as Map<String, dynamic>;
    final token = sessionMap['accessToken'] as String;
    final userInfo = await fetchUserInfo(token);
    return ChatGptSession.fromSessionAndUser(
      rawSessionJson: rawSessionJson,
      userInfo: userInfo,
    );
  }
}
