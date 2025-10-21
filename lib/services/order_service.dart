import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class OrderService {
  OrderService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<List<Order>>> globalSearch(String search) {
    return _api.get<List<Order>>(
      '/order/global-search',
      queryParameters: {'search': search},
      parser: (json) => _parseOrderList(json),
    );
  }

  Future<ApiResponse<PaginatedData<Order>>> list(
    String fromDate,
    String toDate, {
    int page = 1,
    int perPage = 20,
    String status = 'completed',
    String userId = '',
    String search = '',
  }) {
    return _api.get<PaginatedData<Order>>(
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
      parser: (json) => PaginatedData<Order>.fromJson(
        _ensureMap(json),
        (item) => Order.fromJson(_ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Order?>> create(Order order) {
    return _api.post<Order?>(
      '/order',
      data: order.toMap(),
      parser: (json) => json == null ? null : Order.fromJson(_ensureMap(json)),
    );
  }

  Future<ApiResponse<Order?>> update(String id, Order order) {
    return _api.put<Order?>(
      '/order/$id',
      data: order.toMap(),
      parser: (json) => json == null ? null : Order.fromJson(_ensureMap(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> delete(String id) {
    return _api.delete<Map<String, dynamic>?>(
      '/order/$id',
      parser: (json) => json == null ? null : _ensureMap(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> upsertItems(
    String id,
    List<OrderItem> items,
  ) {
    return _api.post<Map<String, dynamic>?>(
      '/order/$id/items',
      data: {'items': items.map((item) => item.toMap()).toList()},
      parser: (json) => json == null ? null : _ensureMap(json),
    );
  }

  Future<ApiResponse<Order>> detail(String id) {
    return _api.get<Order>(
      '/order/$id',
      parser: (json) => Order.fromJson(_ensureMap(json)),
    );
  }
}

List<Order> _parseOrderList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Order.fromJson(_ensureMap(item)))
        .toList(growable: false);
  }
  return <Order>[];
}

Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
