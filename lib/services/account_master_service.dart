import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';
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
      queryParameters: {
        if (isActive != null) 'is_active': isActive,
        if (serviceType != null) 'service_type': serviceType,
      },
      parser: (json) => _parseAccountMasterList(json),
    );
  }

  Future<ApiResponse<AccountMaster>> create(AccountMaster accountMaster) {
    return _api.post<AccountMaster>(
      '/account-master',
      data: accountMaster.toMap(),
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

  Future<ApiResponse<AccountMaster>> update(
    int id,
    AccountMaster accountMaster,
  ) {
    return _api.put<AccountMaster>(
      '/account-master/$id',
      data: accountMaster.toMap(),
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
  }) {
    return _api.post<AccountSlot>(
      '/account-master/slots/$slotId',
      data: {'name': name, if (pin != null && pin.isNotEmpty) 'pin': pin},
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
