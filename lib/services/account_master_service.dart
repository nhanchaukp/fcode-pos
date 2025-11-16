import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';
import 'package:fcode_pos/models.dart';

class AccountMasterService {
  AccountMasterService() : _api = ApiService();

  final ApiService _api;

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
      parser: (_) => null,
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
}
