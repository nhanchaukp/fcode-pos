import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class RefundService {
  RefundService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<PaginatedData<Refund>>> list({
    String? status,
    String? type,
    String? reason,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'per_page': perPage,
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }
    if (reason != null && reason.isNotEmpty) {
      queryParameters['reason'] = reason;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    return _api.get<PaginatedData<Refund>>(
      '/refund',
      queryParameters: queryParameters,
      parser: (json) => PaginatedData<Refund>.fromJson(
        ensureMap(json),
        (item) => Refund.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Refund>> approve(int id, {String adminNotes = ''}) {
    return _api.post<Refund>(
      '/refund/$id/approve',
      data: {'admin_notes': adminNotes},
      parser: (json) => Refund.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Refund>> reject(int id, {String reason = ''}) {
    return _api.post<Refund>(
      '/refund/$id/reject',
      data: {'reason': reason},
      parser: (json) => Refund.fromJson(ensureMap(json)),
    );
  }
}
