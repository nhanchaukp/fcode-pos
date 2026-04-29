import 'dart:convert';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/models/adsense_models.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AdsenseService {
  AdsenseService({GoogleSignIn? googleSignIn, http.Client? client})
      : _googleSignIn =
            googleSignIn ??
            GoogleSignIn(scopes: const [AdsenseService.adsenseReadonlyScope]),
        _client = client ?? http.Client();

  static const String adsenseReadonlyScope =
      'https://www.googleapis.com/auth/adsense.readonly';
  static const String _adsenseHost = 'adsense.googleapis.com';

  final GoogleSignIn _googleSignIn;
  final http.Client _client;

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  Future<void> signOut() => _googleSignIn.signOut();

  Future<List<AdsenseAccount>> listAccounts(
    GoogleSignInAccount account,
  ) async {
    final token = await _getAccessToken(account);
    final uri = _buildUri('/v2/accounts', const {});
    final response = await _client.get(uri, headers: _authHeaders(token));
    final body = _decodeResponse(response);
    final rawAccounts = body['accounts'] as List? ?? const [];
    return rawAccounts
        .map(
          (item) => AdsenseAccount.fromJson(
            item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<AdsenseReport> generateReport({
    required GoogleSignInAccount account,
    required String accountName,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> metrics,
    List<String> dimensions = const [],
    List<String> filters = const [],
    int? limit,
  }) async {
    if (metrics.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'Chọn ít nhất một chỉ số báo cáo.',
      );
    }

    final token = await _getAccessToken(account);
    final path = '${_normalizeAccountPath(accountName)}/reports:generate';
    final queryParameters = <String, List<String>>{
      'dateRange': const ['CUSTOM'],
      'startDate.year': [startDate.year.toString()],
      'startDate.month': [startDate.month.toString()],
      'startDate.day': [startDate.day.toString()],
      'endDate.year': [endDate.year.toString()],
      'endDate.month': [endDate.month.toString()],
      'endDate.day': [endDate.day.toString()],
      'metrics': metrics,
    };
    if (dimensions.isNotEmpty) {
      queryParameters['dimensions'] = dimensions;
    }
    if (filters.isNotEmpty) {
      queryParameters['filters'] = filters;
    }
    if (limit != null) {
      queryParameters['limit'] = [limit.toString()];
    }

    final uri = _buildUri(path, queryParameters);
    final response = await _client.get(uri, headers: _authHeaders(token));
    final body = _decodeResponse(response);
    return AdsenseReport.fromJson(body);
  }

  Future<String> _getAccessToken(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Không lấy được access token Google. Vui lòng đăng nhập lại.',
      );
    }
    return token;
  }

  Uri _buildUri(String path, Map<String, List<String>> queryParameters) {
    final query = _encodeQueryParameters(queryParameters);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('https://$_adsenseHost$normalizedPath$query');
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
      } else {
        body = {};
      }
    } catch (e) {
      debugPrint('Error decoding AdSense response: $e');
      body = {};
    }

    if (response.statusCode >= 400) {
      final error = body['error'];
      String message = 'Không thể lấy dữ liệu AdSense.';
      if (error is Map) {
        message = error['message']?.toString() ?? message;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
        data: body,
      );
    }

    return body;
  }

  String _normalizeAccountPath(String accountName) {
    final normalized = accountName.startsWith('accounts/')
        ? accountName
        : 'accounts/$accountName';
    return '/v2/$normalized';
  }

  String _encodeQueryParameters(Map<String, List<String>> params) {
    if (params.isEmpty) return '';
    final parts = <String>[];
    params.forEach((key, values) {
      for (final value in values) {
        parts.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    });
    return '?${parts.join('&')}';
  }
}
