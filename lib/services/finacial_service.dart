import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

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

  Future<ApiResponse<List<FinancialSummary>>> monthly() {
    return _api.get<List<FinancialSummary>>(
      '/financial/monthly',
      parser: (json) =>
          (json as List?)
              ?.map((e) => FinancialSummary.fromJson(ensureMap(e)))
              .toList() ??
          [],
    );
  }

  Future<ApiResponse<PaginatedData<FinancialTransaction>>>
  getFinancialTransaction({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    int page = 1,
    int perPage = 15,
  }) {
    return _api.get<PaginatedData<FinancialTransaction>>(
      '/financial-transaction',
      queryParameters: {
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'per_page': perPage,
      },
      parser: (json) => PaginatedData<FinancialTransaction>.fromJson(
        ensureMap(json),
        (item) => FinancialTransaction.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> deleteFinancialTransaction(
    int id,
  ) {
    return _api.delete<Map<String, dynamic>?>(
      '/financial-transaction/$id',
      parser: (json) => json as Map<String, dynamic>?,
    );
  }
}
