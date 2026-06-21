import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AccountMasterBrowserService {
  static const _defaultUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1';

  static String resolveInitialUrl({
    required String serviceType,
    String? details,
  }) {
    final trimmedDetails = details?.trim();
    if (trimmedDetails != null && trimmedDetails.isNotEmpty) {
      if (_looksLikeUrl(trimmedDetails)) {
        return trimmedDetails;
      }
    }

    return switch (serviceType) {
      'netflix' => 'https://www.netflix.com/',
      'youtube' => 'https://www.youtube.com/',
      'google_one' => 'https://one.google.com/',
      'chatgpt' => 'https://chatgpt.com/',
      'microsoft' => 'https://account.microsoft.com/',
      _ => 'https://www.google.com/',
    };
  }

  static bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Normalizes user input into a navigable http(s) URL, or null if invalid.
  static String? normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (_looksLikeUrl(trimmed)) {
      return trimmed;
    }

    final withScheme = Uri.tryParse('https://$trimmed');
    if (withScheme != null &&
        withScheme.host.isNotEmpty &&
        !withScheme.host.contains(' ')) {
      return withScheme.toString();
    }

    return null;
  }

  /// Clear all cookies and web storage so each account starts an isolated session.
  Future<void> clearSession() async {
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

    debugPrint('[AccountMasterBrowser] cleared WebView session');
  }

  /// Inject stored cookies into WebView for [url]. Skips when [cookies] is empty.
  Future<void> injectCookies({
    required String? cookies,
    required String url,
    InAppWebViewController? webViewController,
  }) async {
    final parsed = parseCookieEntries(cookies);
    if (parsed.isEmpty) return;

    final uri = Uri.parse(url);
    final cookieManager = CookieManager.instance();
    final cookieDomain = cookieDomainForHost(uri.host);
    final cookieUrl = urlForCookieDomain(
      scheme: uri.scheme,
      domain: cookieDomain,
      fallbackHost: uri.host,
    );
    final defaultExpires =
        DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch;
    final isHttps = uri.scheme == 'https';

    for (final entry in parsed) {
      final httpOnly = _shouldUseHttpOnly(entry.name);

      await cookieManager.setCookie(
        url: WebUri(cookieUrl),
        name: entry.name,
        value: entry.value,
        domain: cookieDomain,
        path: '/',
        expiresDate: defaultExpires,
        isSecure: isHttps && _shouldUseSecure(entry.name, isHttps),
        isHttpOnly: httpOnly,
        sameSite: httpOnly
            ? HTTPCookieSameSitePolicy.NONE
            : HTTPCookieSameSitePolicy.LAX,
        webViewController: webViewController,
      );
    }

    debugPrint(
      '[AccountMasterBrowser] injected ${parsed.length} cookies for $cookieDomain',
    );
  }

  /// Capture cookies as `name=value; name2=value2` string.
  Future<String> captureCookiesAsString({String? relatedUrl}) async {
    final cookies = await CookieManager.instance().getAllCookies();
    final filtered = relatedUrl == null
        ? cookies
        : cookies
              .where((cookie) => cookieBelongsToUrl(cookie, relatedUrl))
              .toList(growable: false);

    if (filtered.isEmpty) return '';

    return filtered.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  static bool _shouldUseHttpOnly(String name) {
    final lower = name.toLowerCase();
    return lower == 'netflixid' ||
        lower == 'securenetflixid' ||
        lower == 'nfvdid' ||
        lower == 'gsid' ||
        lower == 'flwssn';
  }

  static bool _shouldUseSecure(String name, bool isHttps) {
    if (!isHttps) return false;

    final lower = name.toLowerCase();
    return _shouldUseHttpOnly(name) || lower.startsWith('secure');
  }

  static String cookieDomainForHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized.startsWith('www.')) {
      return '.${normalized.substring(4)}';
    }

    final parts = normalized.split('.');
    if (parts.length >= 2) {
      return '.${parts.sublist(parts.length - 2).join('.')}';
    }

    return '.$normalized';
  }

  static String urlForCookieDomain({
    required String scheme,
    required String domain,
    required String fallbackHost,
  }) {
    if (domain.startsWith('.')) {
      return '$scheme://www$domain/';
    }
    return '$scheme://${domain.isNotEmpty ? domain : fallbackHost}/';
  }

  static bool cookieBelongsToUrl(Cookie cookie, String url) {
    final host = Uri.parse(url).host.toLowerCase();
    final rawDomain = cookie.domain?.toLowerCase() ?? '';
    if (rawDomain.isEmpty) return true;

    final domain =
        rawDomain.startsWith('.') ? rawDomain.substring(1) : rawDomain;
    return host == domain || host.endsWith('.$domain') || domain.endsWith(host);
  }

  static List<AccountMasterCookieEntry> parseCookieEntries(String? raw) {
    if (raw == null) return const [];

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];

    return trimmed
        .split(RegExp(r';\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(_parseNameValuePair)
        .whereType<AccountMasterCookieEntry>()
        .toList(growable: false);
  }

  static AccountMasterCookieEntry? _parseNameValuePair(String part) {
    final separatorIndex = part.indexOf('=');
    if (separatorIndex <= 0) return null;

    final name = part.substring(0, separatorIndex).trim();
    final value = part.substring(separatorIndex + 1).trim();
    if (name.isEmpty) return null;

    return AccountMasterCookieEntry(name: name, value: value);
  }

  static InAppWebViewSettings defaultSettings() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheEnabled: true,
      sharedCookiesEnabled: true,
      thirdPartyCookiesEnabled: true,
      useShouldOverrideUrlLoading: false,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      userAgent: _defaultUserAgent,
    );
  }

  static Future<ServerTrustAuthResponse> handleServerTrustAuthRequest(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  ) async {
    final host = challenge.protectionSpace.host;
    debugPrint('[AccountMasterBrowser] server trust challenge: $host');

    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.PROCEED,
    );
  }
}

class AccountMasterCookieEntry {
  final String name;
  final String value;

  const AccountMasterCookieEntry({required this.name, required this.value});
}