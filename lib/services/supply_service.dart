import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class SupplyService {
  SupplyService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<PaginatedData<Supply>>> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<Supply>>(
      '/supply',
      queryParameters: {'search': search, 'page': page, 'per_page': perPage},
      parser: (json) => PaginatedData<Supply>.fromJson(
        _ensureMap(json),
        (item) => Supply.fromJson(_ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Supply>> detail(String id) {
    return _api.get<Supply>(
      '/supply/$id',
      parser: (json) => Supply.fromJson(_ensureMap(json)),
    );
  }

  Future<ApiResponse<Supply>> create(Map<String, dynamic> data) {
    return _api.post<Supply>(
      '/supply',
      data: data,
      parser: (json) => Supply.fromJson(_ensureMap(json)),
    );
  }

  Future<ApiResponse<Supply>> update(int id, Map<String, dynamic> data) {
    return _api.put<Supply>(
      '/supply/$id',
      data: data,
      parser: (json) => Supply.fromJson(_ensureMap(json)),
    );
  }
}

Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
