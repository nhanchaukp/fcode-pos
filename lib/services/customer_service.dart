import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class CustomerService {
  CustomerService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<PaginatedData<User>>> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<User>>(
      '/user',
      queryParameters: {
        'search': search,
        'page': page,
        'per_page': perPage,
      },
      parser: (json) => PaginatedData<User>.fromJson(
        _ensureMap(json),
        (item) => User.fromJson(_ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<User>> detail(String id) {
    return _api.get<User>(
      '/user/$id',
      parser: (json) => User.fromJson(_ensureMap(json)),
    );
  }
}

Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
