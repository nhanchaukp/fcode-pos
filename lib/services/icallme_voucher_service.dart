import 'package:fcode_pos/models/icallme_voucher.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/services/api_service.dart';

class IcallmeVoucherService {
  IcallmeVoucherService() : _api = ApiService();

  final ApiService _api;

  /// Lấy danh sách voucher có phân trang và bộ lọc.
  ///
  /// [status]        - Lọc theo trạng thái: available / used / revoked / expired
  /// [externalRefId] - Lọc theo ref ID (ORDER-xxx)
  /// [fromDate]      - Từ ngày (ISO 8601, ví dụ: 2026-01-01T00:00:00Z)
  /// [toDate]        - Đến ngày (ISO 8601)
  /// [page]          - Trang hiện tại (mặc định 1)
  /// [limit]         - Số item mỗi trang (mặc định 20)
  Future<ApiResponse<IcalmePagedResult<IcallmeVoucher>>> list({
    String? status,
    String? externalRefId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) {
    return _api.get<IcalmePagedResult<IcallmeVoucher>>(
      '/icallme/vouchers',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (externalRefId != null && externalRefId.isNotEmpty)
          'externalRefId': externalRefId,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
      parser: (json) {
        if (json is! Map<String, dynamic>) {
          return IcalmePagedResult<IcallmeVoucher>(
            items: [],
            page: 1,
            limit: limit,
            total: 0,
            totalPages: 0,
          );
        }
        return IcalmePagedResult<IcallmeVoucher>.fromJson(
          json,
          IcallmeVoucher.fromJson,
        );
      },
    );
  }

  /// Lấy chi tiết một voucher theo mã code.
  Future<ApiResponse<IcallmeVoucher>> show(String voucherCode) {
    return _api.get<IcallmeVoucher>(
      '/icallme/vouchers/$voucherCode',
      parser: (json) {
        if (json is! Map<String, dynamic>) throw Exception('Invalid response');
        return IcallmeVoucher.fromJson(json);
      },
    );
  }

  /// Lấy tổng quan thống kê voucher.
  Future<ApiResponse<IcallmeVoucherSummary>> summary() {
    return _api.get<IcallmeVoucherSummary>(
      '/icallme/vouchers/summary',
      parser: (json) {
        if (json is! Map<String, dynamic>) throw Exception('Invalid response');
        return IcallmeVoucherSummary.fromJson(json);
      },
    );
  }

  /// Thu hồi voucher chưa được sử dụng.
  Future<ApiResponse<IcallmeVoucher>> revoke(String voucherCode) {
    return _api.post<IcallmeVoucher>(
      '/icallme/vouchers/$voucherCode/revoke',
      parser: (json) {
        if (json is! Map<String, dynamic>) throw Exception('Invalid response');
        return IcallmeVoucher.fromJson(json);
      },
    );
  }

  /// Tạo voucher mới theo gói.
  ///
  /// [packageId]       - person_year | person_lifetime | group_year | group_lifetime
  /// [externalRefId]   - Mã tham chiếu ngoài (ví dụ ORDER-xxx)
  /// [externalMetadata]- JSON metadata tùy chỉnh
  Future<ApiResponse<IcallmeVoucher>> create({
    required String packageId,
    required String externalRefId,
    Map<String, dynamic>? externalMetadata,
  }) {
    return _api.post<IcallmeVoucher>(
      '/icallme/vouchers/package/$packageId',
      data: {
        'externalRefId': externalRefId,
        if (externalMetadata != null && externalMetadata.isNotEmpty)
          'externalMetadata': externalMetadata,
      },
      parser: (json) {
        if (json is! Map<String, dynamic>) throw Exception('Invalid response');
        return IcallmeVoucher.fromJson(json);
      },
    );
  }
}
