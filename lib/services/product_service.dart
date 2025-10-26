import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/models/dto/product_update_data.dart';
import 'package:fcode_pos/utils/extensions.dart';

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
      queryParameters: {'search': search, 'page': page, 'per_page': perPage},
      parser: (json) => PaginatedData<Product>.fromJson(
        ensureMap(json),
        (item) => Product.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Product>> detail(String id) {
    return _api.get<Product>(
      '/product/$id',
      parser: (json) => Product.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Product>> update(ProductUpdateData data, int id) {
    return _api.put<Product>(
      '/product/$id',
      data: data.toJson(),
      parser: (json) => Product.fromJson(ensureMap(json)),
    );
  }
}
