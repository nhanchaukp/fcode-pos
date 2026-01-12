import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/models/dto/customer_create_data.dart';
import 'package:fcode_pos/utils/extensions.dart';

class CustomerService {
  CustomerService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<User>> create(CustomerCreateData data) {
    return _api.post<User>(
      '/user',
      data: data.toJson(),
      parser: (json) => User.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<PaginatedData<User>>> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<User>>(
      '/user',
      queryParameters: {'search': search, 'page': page, 'per_page': perPage},
      parser: (json) => PaginatedData<User>.fromJson(
        ensureMap(json),
        (item) => User.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<User>> detail(int id) {
    return _api.get<User>(
      '/user/$id',
      parser: (json) => User.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<CustomerStats>> stats() {
    return _api.get<CustomerStats>(
      '/user/stats',
      parser: (json) => CustomerStats.fromJson(ensureMap(json)),
    );
  }
}
