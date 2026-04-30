import 'dart:convert';
import 'dart:io';

import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class ChatGptSessionService {
  static const _sessionUrl = 'https://chatgpt.com/api/auth/session';
  static const _chatgptHost = 'https://chatgpt.com';

  /// Đọc cookies từ InAppWebView CookieManager và fetch session từ ChatGPT.
  /// Trả về [ChatGptSession] đã parse, hoặc ném exception nếu chưa đăng nhập.
  Future<ChatGptSession> captureSession() async {
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(
      url: WebUri(_chatgptHost),
    );

    if (cookies.isEmpty) {
      throw Exception('Không tìm thấy cookies. Vui lòng đăng nhập trước.');
    }

    final cookiesJson = _serializeCookiesToJson(cookies);
    final cookieHeader = _buildCookieHeader(cookies);

    final sessionData = await _fetchSessionWithHeader(cookieHeader);
    return ChatGptSession.fromSessionApiJson(
      json: sessionData,
      cookiesJson: cookiesJson,
    );
  }

  /// Fetch lại session ngầm sử dụng cookies đã lưu trong [session].
  /// Trả về session mới nhất với dữ liệu cập nhật.
  Future<ChatGptSession> refreshSession(ChatGptSession session) async {
    final cookieHeader = buildCookieHeaderFromJson(session.cookiesJson);
    final sessionData = await _fetchSessionWithHeader(cookieHeader);
    return ChatGptSession.fromSessionApiJson(
      json: sessionData,
      cookiesJson: session.cookiesJson,
    );
  }

  /// Inject cookies đã lưu từ [session] vào CookieManager để mở browser.
  Future<void> injectCookies(ChatGptSession session) async {
    final cookieManager = CookieManager.instance();
    final cookies = _deserializeCookiesFromJson(session.cookiesJson);

    for (final cookie in cookies) {
      await cookieManager.setCookie(
        url: WebUri(_chatgptHost),
        name: cookie['name'] as String,
        value: cookie['value'] as String,
        domain: cookie['domain'] as String?,
        path: cookie['path'] as String? ?? '/',
        isSecure: cookie['isSecure'] as bool? ?? true,
        isHttpOnly: cookie['isHttpOnly'] as bool? ?? false,
      );
    }
  }

  /// Xóa toàn bộ cookies và web storage của WebView để đảm bảo browser sạch.
  /// Dùng deleteAllCookies() vì ChatGPT lưu cookies trên nhiều domain
  /// (chatgpt.com, openai.com, auth0.openai.com, ...).
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

  String buildCookieHeaderFromJson(String cookiesJson) {
    final cookies = _deserializeCookiesFromJson(cookiesJson);
    return cookies
        .map((c) => '${c['name']}=${c['value']}')
        .join('; ');
  }

  Future<Map<String, dynamic>> _fetchSessionWithHeader(
      String cookieHeader) async {
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
          'Không thể lấy thông tin session (HTTP ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final user = json['user'];
    if (user == null) {
      throw Exception('Chưa đăng nhập hoặc session đã hết hạn.');
    }

    return json;
  }

  String _buildCookieHeader(List<Cookie> cookies) {
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }

  String _serializeCookiesToJson(List<Cookie> cookies) {
    return jsonEncode(cookies.map((c) => {
          'name': c.name,
          'value': c.value,
          'domain': c.domain,
          'path': c.path,
          'isSecure': c.isSecure,
          'isHttpOnly': c.isHttpOnly,
          'expiresDate': c.expiresDate,
        }).toList());
  }

  List<Map<String, dynamic>> _deserializeCookiesFromJson(String cookiesJson) {
    try {
      final list = jsonDecode(cookiesJson) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
