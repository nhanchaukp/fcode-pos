import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class CouponService {
  CouponService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<PaginatedData<Coupon>>> list({
    String search = '',
    String type = '',
    bool? isEnabled,
    String sort = '',
    String direction = '',
    int perPage = 15,
    int page = 1,
  }) {
    return _api.get<PaginatedData<Coupon>>(
      '/coupon',
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (type.isNotEmpty) 'type': type,
        if (isEnabled != null) 'is_enabled': isEnabled ? 1 : 0,
        if (sort.isNotEmpty) 'sort': sort,
        if (direction.isNotEmpty) 'direction': direction,
        'per_page': perPage,
        'page': page,
      },
      parser: (json) => PaginatedData<Coupon>.fromJson(
        ensureMap(json),
        (item) => Coupon.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Coupon>> detail(int id) {
    return _api.get<Coupon>(
      '/coupon/$id',
      parser: (json) => Coupon.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Coupon?>> create(Map<String, dynamic> data) {
    return _api.post<Coupon?>(
      '/coupon',
      data: data,
      parser: (json) => json == null ? null : Coupon.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Coupon?>> update(int id, Map<String, dynamic> data) {
    return _api.put<Coupon?>(
      '/coupon/$id',
      data: data,
      parser: (json) => json == null ? null : Coupon.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> delete(int id) {
    return _api.delete<Map<String, dynamic>?>(
      '/coupon/$id',
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }

  Future<ApiResponse<Coupon?>> toggle(int id) {
    return _api.post<Coupon?>(
      '/coupon/$id/toggle',
      parser: (json) => json == null ? null : Coupon.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<PaginatedData<CouponUsage>>> usage(
    int id, {
    int perPage = 15,
    int page = 1,
  }) {
    return _api.get<PaginatedData<CouponUsage>>(
      '/coupon/$id/usage',
      queryParameters: {
        'per_page': perPage,
        'page': page,
      },
      parser: (json) => PaginatedData<CouponUsage>.fromJson(
        ensureMap(json),
        (item) => CouponUsage.fromJson(ensureMap(item)),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> validate({
    required String code,
    required int userId,
    required int totalAmount,
  }) {
    return _api.post<Map<String, dynamic>>(
      '/coupon/validate',
      data: {
        'code': code,
        'user_id': userId,
        'total_amount': totalAmount,
      },
      parser: (json) => ensureMap(json),
    );
  }
}
