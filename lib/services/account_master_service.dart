import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';
import 'package:fcode_pos/models/dto/account_master_data.dart';
import 'package:fcode_pos/models/dto/account_master_filter.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/utils/functions.dart';

class AccountMasterService {
  AccountMasterService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<List<AccountMaster>>> list({
    bool? isActive,
    String? serviceType,
  }) {
    return _api.get<List<AccountMaster>>(
      '/account-master',
      queryParameters: {'is_active': ?isActive, 'service_type': ?serviceType},
      parser: (json) => _parseAccountMasterList(json),
    );
  }

  Future<ApiResponse<List<AccountMaster>>> filter({
    required AccountMasterFilter filter,
  }) {
    return _api.get<List<AccountMaster>>(
      '/account-master/filter',
      queryParameters: filter.toJson(),
      parser: (json) => _parseAccountMasterList(json),
    );
  }

  Future<ApiResponse<AccountMasterStats>> stats({
    required AccountMasterFilter filter,
  }) {
    return _api.get<AccountMasterStats>(
      '/account-master/stats',
      queryParameters: filter.toJson(),
      parser: (json) => AccountMasterStats.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<AccountMaster>> getById(int id) {
    return _api.get<AccountMaster>(
      '/account-master/$id',
      parser: (json) => AccountMaster.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountMaster>> syncNetflixInfo(int id) {
    return _api.get<AccountMaster>(
      '/account-master/$id/sync-netflix',
      parser: (json) => AccountMaster.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> getAllCode(int id) {
    return _api.get<dynamic>(
      '/account-master/$id/get-all-code',
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<String>>> getExternalSources() {
    return _api.get<List<String>>(
      '/account-master/external-sources',
      parser: (json) {
        if (json is List) {
          return json.map((e) => e.toString()).toList(growable: false);
        }
        if (json is Map) {
          final items = json['items'] ?? json['data'] ?? json['external_sources'];
          if (items is List) {
            return items.map((e) => e.toString()).toList(growable: false);
          }
          return json.values.map((e) => e.toString()).toList(growable: false);
        }
        return <String>[];
      },
    );
  }

  Future<ApiResponse<AccountMaster>> create(AccountMasterData data) {
    return _api.post<AccountMaster>(
      '/account-master',
      data: data.toJson(),
      parser: (json) => AccountMaster.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> createExpense(AccountExpenseCreateData data) {
    return _api.post<void>(
      '/account-master/expense',
      data: data.toJson(),
      parser: (_) {},
    );
  }

  Future<ApiResponse<PaginatedData<FinancialTransaction>>> getExpense(int id) {
    return _api.get<PaginatedData<FinancialTransaction>>(
      '/account-master/$id/expense',
      parser: (json) => PaginatedData<FinancialTransaction>.fromJson(
        ensureMap(json),
        (item) => FinancialTransaction.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<AccountMaster>> update(int id, AccountMasterData data) {
    return _api.put<AccountMaster>(
      '/account-master/$id',
      data: data.toJson(),
      parser: (json) => AccountMaster.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountSlot>> addSlot(
    int accountMasterId, {
    required String name,
    String? pin,
  }) {
    return _api.post<AccountSlot>(
      '/account-master/$accountMasterId/add-slot',
      data: {'name': name, if (pin != null && pin.isNotEmpty) 'pin': pin},
      parser: (json) => AccountSlot.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountSlot>> updateSlot(
    int slotId, {
    required String name,
    String? pin,
    bool isActive = true,
  }) {
    return _api.post<AccountSlot>(
      '/account-master/slots/$slotId',
      data: {
        'name': name,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        'is_active': isActive,
      },
      parser: (json) => AccountSlot.fromJson(json as Map<String, dynamic>),
    );
  }
}

List<AccountMaster> _parseAccountMasterList(dynamic data) {
  if (data is List) {
    return data
        .map((item) => AccountMaster.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  if (data is Map) {
    final items = data['items'] ?? data['data'];
    if (items is List) {
      return items
          .map((item) => AccountMaster.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    }
  }

  return <AccountMaster>[];
}
