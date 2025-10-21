import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class ProductService {
  ProductService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<PaginatedData<Product>>> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<Product>>(
      '/product',
      queryParameters: {
        'search': search,
        'page': page,
        'per_page': perPage,
      },
      parser: (json) => PaginatedData<Product>.fromJson(
        _ensureMap(json),
        (item) => Product.fromJson(_ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Product>> detail(String id) {
    return _api.get<Product>(
      '/product/$id',
      parser: (json) => Product.fromJson(_ensureMap(json)),
    );
  }
}

Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
