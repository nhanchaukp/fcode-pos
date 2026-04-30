import 'dart:convert';

import 'package:fcode_pos/models/adsense_models.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AdsenseService {
  static const _scopes = ['https://www.googleapis.com/auth/adsense.readonly'];
  static const _baseUrl = 'https://adsense.googleapis.com/v2';

  // Metrics requested in a fixed order matching AdsenseReportRow.fromCells parsing:
  // cells[1]=ESTIMATED_EARNINGS, [2]=PAGE_VIEWS, [3]=CLICKS,
  // [4]=PAGE_VIEWS_RPM, [5]=IMPRESSIONS, [6]=PAGE_VIEWS_CTR, [7]=COST_PER_CLICK
  static const _metrics = [
    'ESTIMATED_EARNINGS',
    'PAGE_VIEWS',
    'CLICKS',
    'PAGE_VIEWS_RPM',
    'IMPRESSIONS',
    'PAGE_VIEWS_CTR',
    'COST_PER_CLICK',
  ];

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  /// Xác thực người dùng và yêu cầu quyền AdSense.
  /// Phải được gọi từ tương tác người dùng (button tap).
  Future<GoogleSignInAccount> signIn() async {
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _scopes,
    );
    // Yêu cầu authorization ngay sau sign-in (trong context user interaction)
    await account.authorizationClient.authorizeScopes(_scopes);
    return account;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }

  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    return await GoogleSignIn.instance.attemptLightweightAuthentication();
  }

  Future<Map<String, String>> _headers(GoogleSignInAccount account) async {
    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: false,
    );
    if (headers == null) {
      throw const _AdsenseAuthException(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại.',
      );
    }
    return headers;
  }

  Future<List<AdsenseAccount>> getAccounts(GoogleSignInAccount account) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/accounts'),
      headers: await _headers(account),
    );
    _checkStatus(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['accounts'] as List<dynamic>?) ?? [];
    return list
        .map((e) => AdsenseAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdsenseReport> generateReport({
    required GoogleSignInAccount account,
    required String accountName,
    required AdsenseDateRange dateRange,
    required AdsenseDimension dimension,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final parts = <String>[
      'dateRange=${Uri.encodeQueryComponent(dateRange.apiValue)}',
      'dimensions=${Uri.encodeQueryComponent(dimension.apiValue)}',
      ..._metrics.map((m) => 'metrics=${Uri.encodeQueryComponent(m)}'),
    ];

    if (dateRange == AdsenseDateRange.custom &&
        startDate != null &&
        endDate != null) {
      parts.addAll([
        'startDate.year=${startDate.year}',
        'startDate.month=${startDate.month}',
        'startDate.day=${startDate.day}',
        'endDate.year=${endDate.year}',
        'endDate.month=${endDate.month}',
        'endDate.day=${endDate.day}',
      ]);
    }

    final url = '$_baseUrl/$accountName/reports:generate?${parts.join('&')}';
    debugPrint('[AdSense] GET $url');
    final response = await http.get(Uri.parse(url), headers: await _headers(account));
    if (response.statusCode != 200) {
      debugPrint('[AdSense] report ERROR status=${response.statusCode} body=${response.body}');
    } else {
      debugPrint('[AdSense] report OK status=200');
    }
    _checkStatus(response);
    return AdsenseReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Lấy thu nhập ước tính cho 4 khoảng thời gian.
  /// Dùng generateReport (đã hoạt động tốt) để đảm bảo parse đúng.
  Future<AdsenseEarningsOverview> getEarningsOverview({
    required GoogleSignInAccount account,
    required String accountName,
  }) async {
    Future<double> earnFor(AdsenseDateRange range) async {
      try {
        // Dùng dimension=DATE để lấy totals.estimatedEarnings — cách duy nhất
        // đáng tin cậy vì no-dimension API có response format không nhất quán.
        final report = await generateReport(
          account: account,
          accountName: accountName,
          dateRange: range,
          dimension: AdsenseDimension.date,
        );
        return report.totals?.estimatedEarnings ?? 0;
      } catch (_) {
        return 0;
      }
    }

    // Sequential để tránh rate-limit khi gọi nhiều API cùng lúc
    final today = await earnFor(AdsenseDateRange.today);
    final yesterday = await earnFor(AdsenseDateRange.yesterday);
    final last7 = await earnFor(AdsenseDateRange.last7Days);
    final thisMonth = await earnFor(AdsenseDateRange.monthToDate);

    return AdsenseEarningsOverview(
      today: today,
      yesterday: yesterday,
      last7Days: last7,
      thisMonth: thisMonth,
    );
  }

  // Metrics cho section Hiệu suất (không có dimension, thứ tự khớp với AdsensePerformanceData.fromCells)
  static const _performanceMetrics = [
    'PAGE_VIEWS',
    'PAGE_VIEWS_RPM',
    'IMPRESSIONS',
    'CLICKS',
    'COST_PER_CLICK',
    'PAGE_VIEWS_CTR',
  ];

  /// Lấy 6 chỉ số hiệu suất cho một khoảng thời gian (không có dimension).
  Future<AdsensePerformanceData> getPerformanceMetrics({
    required GoogleSignInAccount account,
    required String accountName,
    required AdsenseDateRange dateRange,
  }) async {
    final parts = [
      'dateRange=${Uri.encodeQueryComponent(dateRange.apiValue)}',
      ..._performanceMetrics.map((m) => 'metrics=${Uri.encodeQueryComponent(m)}'),
    ];
    final url = '$_baseUrl/$accountName/reports:generate?${parts.join('&')}';
    debugPrint('[AdSense] performance GET $url');
    final response = await http.get(Uri.parse(url), headers: await _headers(account));
    debugPrint('[AdSense] performance status=${response.statusCode} body=${response.body}');
    _checkStatus(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    List<dynamic>? cells;
    final rows = json['rows'] as List<dynamic>?;
    if (rows != null && rows.isNotEmpty) {
      cells = (rows.first as Map<String, dynamic>)['cells'] as List<dynamic>?;
    } else {
      cells = (json['totals'] as Map<String, dynamic>?)?['cells'] as List<dynamic>?;
    }
    return AdsensePerformanceData.fromCells(cells ?? []);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      String msg;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        msg = (json['error'] as Map?)?['message']?.toString() ??
            'Lỗi HTTP ${response.statusCode}';
      } catch (_) {
        msg = 'Lỗi HTTP ${response.statusCode}: ${response.body}';
      }
      debugPrint('[AdSense] ERROR: $msg');
      throw Exception(msg);
    }
  }
}

class _AdsenseAuthException implements Exception {
  const _AdsenseAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
