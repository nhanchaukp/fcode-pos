import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class AuthService {
  final _api = ApiService().dio;

  Future<List<Order>> globalSearch(String search) async {
    final res = await _api.get(
      '/order/global-search',
      queryParameters: {'search': search},
    );
    if (res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<OrderPageable> list(
    String fromDate,
    String toDate, {
    int page = 1,
    int perPage = 20,
    String status = 'completed',
    String userId = '',
    String search = '',
  }) async {
    final res = await _api.get(
      '/order',
      queryParameters: {
        'date_from': fromDate,
        'date_to': toDate,
        'page': page,
        'per_page': perPage,
        'status': status,
        'user_id': userId,
        'search': search,
      },
    );

    return OrderPageable.fromJson(res.data);
  }

  Future<void> create(Order order) async {
    await _api.post('/order', data: order.toMap());
  }

  Future<void> update(String id, Order order) async {
    await _api.put('/order/$id', data: order.toMap());
  }

  Future<void> delete(String id) async {
    await _api.delete('/order/$id');
  }

  Future<void> upsertItems(String id, List<OrderItem> items) async {
    await _api.post(
      '/order/$id/items',
      data: {'items': items.map((item) => item.toMap()).toList()},
    );
  }

  Future<Order> detail(String id) async {
    final res = await _api.get('/order/$id');
    return Order.fromJson(res.data['data']);
  }
}
