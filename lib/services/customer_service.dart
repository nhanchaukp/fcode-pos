import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class CustomerService {
  final _api = ApiService().dio;

  Future<UserPageable> list({
    String search = '',
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.get(
      '/user',
      queryParameters: {'search': search, 'page': page, 'per_page': perPage},
    );

    return UserPageable.fromJson(res.data);
  }

  Future<Order> detail(String id) async {
    final res = await _api.get('/order/$id');
    return Order.fromJson(res.data);
  }
}
