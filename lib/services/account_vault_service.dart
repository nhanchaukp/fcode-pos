import 'dart:convert';

import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:http/http.dart' as http;

class AccountVaultService {
  AccountVaultService() : _api = ApiService();

  final ApiService _api;

  static const _mailGraphApiUrl =
      'https://tools.dongvanfb.net/api/graph_messages';
  static const _mailOAuth2Url =
      'https://tools.dongvanfb.net/api/get_messages_oauth2';

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<ApiResponse<PaginatedData<AccountVaultItem>>> list({
    String? q,
    String? provider,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) {
    return _api.get<PaginatedData<AccountVaultItem>>(
      '/account-vault',
      queryParameters: {
        'q': q,
        'provider': provider,
        if (isActive != null) 'is_active': isActive ? 1 : 0,
        'page': page,
        'per_page': perPage,
      },
      parser: (json) => PaginatedData<AccountVaultItem>.fromJson(
        ensureMap(json),
        (item) => AccountVaultItem.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<List<String>>> providers() {
    return _api.get<List<String>>(
      '/account-vault/providers',
      parser: (json) => (json as List).map((e) => e.toString()).toList(),
    );
  }

  Future<ApiResponse<AccountVault>> detail(int id) {
    return _api.get<AccountVault>(
      '/account-vault/$id',
      parser: (json) => AccountVault.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<AccountVault>> create({
    required String email,
    String? password,
    String? clientId,
    String? provider,
    String? refreshToken,
    String? twoFactorSecret,
    bool isActive = true,
    String? notes,
  }) {
    return _api.post<AccountVault>(
      '/account-vault',
      data: {
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
        if (provider != null && provider.isNotEmpty) 'provider': provider,
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refresh_token': refreshToken,
        if (twoFactorSecret != null && twoFactorSecret.isNotEmpty)
          'two_factor_secret': twoFactorSecret,
        'is_active': isActive,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      parser: (json) => AccountVault.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<AccountVault>> update(
    int id, {
    String? email,
    String? password,
    String? clientId,
    String? provider,
    String? refreshToken,
    String? twoFactorSecret,
    bool? isActive,
    String? notes,
  }) {
    return _api.put<AccountVault>(
      '/account-vault/$id',
      data: {
        'email': ?email,
        'password': ?password,
        'client_id': ?clientId,
        'provider': ?provider,
        'refresh_token': ?refreshToken,
        'two_factor_secret': ?twoFactorSecret,
        'is_active': ?isActive,
        'notes': ?notes,
      },
      parser: (json) => AccountVault.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<void>> delete(int id) {
    return _api.delete<void>('/account-vault/$id', parser: (_) {});
  }

  // ── External Mail APIs ────────────────────────────────────────────────────

  Future<List<VaultMailMessage>> readMailGraphApi({
    required String email,
    required String refreshToken,
    required String clientId,
    bool listAll = false,
  }) => _readMail(
    url: _mailGraphApiUrl,
    email: email,
    refreshToken: refreshToken,
    clientId: clientId,
    listAll: listAll,
  );

  Future<List<VaultMailMessage>> readMailOAuth2({
    required String email,
    required String refreshToken,
    required String clientId,
    bool listAll = false,
  }) => _readMail(
    url: _mailOAuth2Url,
    email: email,
    refreshToken: refreshToken,
    clientId: clientId,
    listAll: listAll,
  );

  Future<List<VaultMailMessage>> _readMail({
    required String url,
    required String email,
    required String refreshToken,
    required String clientId,
    required bool listAll,
  }) async {
    final body = {
      'email': email,
      'refresh_token': refreshToken,
      'client_id': clientId,
      if (listAll) 'list_mail': 'all',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Mail API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != true) {
      // Khi thất bại API trả `content` (e.g. "Graph token invalid.")
      final errMsg = json['content'] ?? json['error'] ?? json['message'];
      throw Exception(errMsg?.toString() ?? 'Đọc mail thất bại');
    }

    final messages = json['messages'] as List? ?? [];
    return messages
        .map((e) => VaultMailMessage.fromJson(ensureMap(e)))
        .toList();
  }
}
