import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';

class AccountMasterService {
  AccountMasterService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<void>> createExpense(AccountExpenseCreateData data) {
    return _api.post<void>(
      '/account-master/expense',
      data: data.toJson(),
      parser: (_) => null,
    );
  }
}
