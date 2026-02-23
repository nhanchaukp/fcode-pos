import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:intl/intl.dart';

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

  Future<ApiResponse<PaginatedData<Order>>> list({
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 20,
    String status = '',
    String userId = '',
    String search = '',
  }) {
    return _api.get<PaginatedData<Order>>(
      '/order',
      queryParameters: {
        'date_from': fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate)
            : null,
        'date_to': toDate != null
            ? DateFormat('yyyy-MM-dd').format(toDate)
            : null,
        'page': page,
        'per_page': perPage,
        'status': status,
        'user_id': userId,
        'search': search,
      },
      parser: (json) => PaginatedData<Order>.fromJson(
        ensureMap(json),
        (item) => Order.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<OrderSummary>> summary({
    DateTime? fromDate,
    DateTime? toDate,
    String status = '',
    String userId = '',
    String search = '',
  }) {
    return _api.get<OrderSummary>(
      '/order/summary',
      queryParameters: {
        'date_from': fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate)
            : null,
        'date_to': toDate != null
            ? DateFormat('yyyy-MM-dd').format(toDate)
            : null,
        'status': status,
        'user_id': userId,
        'search': search,
      },
      parser: (json) => OrderSummary.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<OrderStats>> stats(DateTime fromDate, DateTime toDate) {
    return _api.get<OrderStats>(
      '/order/stats',
      queryParameters: {
        'date_from': DateFormat('yyyy-MM-dd').format(fromDate),
        'date_to': DateFormat('yyyy-MM-dd').format(toDate),
      },
      parser: (json) => OrderStats.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Order?>> create(Order order) {
    return _api.post<Order?>(
      '/order',
      data: order.toMap(),
      parser: (json) => json == null ? null : Order.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Order?>> update(String id, Order order) {
    return _api.put<Order?>(
      '/order/$id',
      data: order.toMap(),
      parser: (json) => json == null ? null : Order.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> delete(String id) {
    return _api.delete<Map<String, dynamic>?>(
      '/order/$id',
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> upsertItems(
    int id,
    List<OrderItem> items,
  ) {
    return _api.post<Map<String, dynamic>?>(
      '/order/$id/items',
      data: {'items': items.map((item) => item.toMap()).toList()},
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }

  Future<ApiResponse<Order>> detail(String id) {
    return _api.get<Order>(
      '/order/$id',
      parser: (json) => Order.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> deleteItem(
    int orderId,
    int itemId,
  ) {
    return _api.delete<Map<String, dynamic>?>(
      '/order/$orderId/item/$itemId',
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }
}

List<Order> _parseOrderList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Order.fromJson(ensureMap(item)))
        .toList(growable: false);
  }
  return <Order>[];
}
