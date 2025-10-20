import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class ProductService {
  final _api = ApiService().dio;

  Future<ProductPageable> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.get(
      '/product',
      queryParameters: {'search': search, 'page': page, 'per_page': perPage},
    );

    return ProductPageable.fromJson(res.data);
  }

  Future<Product> detail(String id) async {
    final res = await _api.get('/product/$id');
    return Product.fromJson(res.data);
  }
}
