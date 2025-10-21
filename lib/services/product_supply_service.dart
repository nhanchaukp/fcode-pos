import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class ProductSupplyService {
  ProductSupplyService() : _api = ApiService();

  final ApiService _api;

  /// Get best price for a product (lowest price from all supplies)
  Future<ApiResponse<ProductSupply?>> bestPrice(
    int productId, {
    int? supplyId,
  }) {
    return _api.get<ProductSupply?>(
      '/product-supply/best-price/$productId',
      queryParameters: {'supply_id': supplyId},
      parser: (json) => _parseSingleProductSupply(json),
    );
  }

  /// Get a specific product-supply mapping
  Future<ApiResponse<ProductSupply?>> detail(int id) {
    return _api.get<ProductSupply?>(
      '/product-supply/$id',
      parser: (json) =>
          json == null ? null : ProductSupply.fromJson(_ensureMap(json)),
    );
  }

  /// List all product-supply mappings with pagination support
  Future<ApiResponse<PaginatedData<ProductSupply>>> list({
    int? productId,
    int? supplyId,
    String search = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<ProductSupply>>(
      '/product-supply',
      queryParameters: {
        'product_id': productId,
        'supply_id': supplyId,
        'search': search,
        'page': page,
        'per_page': perPage,
      },
      parser: (json) => PaginatedData<ProductSupply>.fromJson(
        _ensureMap(json),
        (item) => ProductSupply.fromJson(_ensureMap(item)),
      ),
    );
  }
}

ProductSupply? _parseSingleProductSupply(dynamic data) {
  if (data == null) return null;

  if (data is Map) {
    if (data.containsKey('items')) {
      final items = data['items'];
      if (items is List && items.isNotEmpty) {
        final first = items.first;
        if (first is Map) {
          return ProductSupply.fromJson(_ensureMap(first));
        }
      }
    }
    return ProductSupply.fromJson(_ensureMap(data));
  }

  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map) {
      return ProductSupply.fromJson(_ensureMap(first));
    }
  }

  return null;
}

Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
