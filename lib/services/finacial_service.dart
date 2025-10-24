import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions/num_extensions.dart';

class FinacialService {
  FinacialService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<FinancialReport>> report({
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _api.get<FinancialReport>(
      '/financial/report',
      queryParameters: {
        if (fromDate != null) 'start_date': fromDate.toIso8601String(),
        if (toDate != null) 'end_date': toDate.toIso8601String(),
      },
      parser: (json) => FinancialReport.fromJson(ensureMap(json)),
    );
  }
}
