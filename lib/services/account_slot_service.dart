import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class AccountSlotService {
  AccountSlotService() : _api = ApiService();

  final ApiService _api;

  Future<ApiResponse<List<AccountMaster>>> listMaster({
    int? accountMasterId,
    bool? isActive,
    String? serviceType,
    String? search,
    int? daysRemaining,
    bool? isFreeSlot,
    int? supplyId,
  }) {
    return _api.get<List<AccountMaster>>(
      '/account-slots',
      queryParameters: {
        'account_master_id': ?accountMasterId,
        'is_active': ?isActive,
        if (serviceType != null) 'service_type': serviceType.toLowerCase(),
        'search': ?search,
        'days_remaining': ?daysRemaining,
        'is_free_slot': ?isFreeSlot,
        'supply_id': ?supplyId,
      },
      parser: (json) => _parseAccountMasterList(json),
    );
  }

  Future<ApiResponse<List<AccountSlot>>> available(int? includeId) {
    return _api.get<List<AccountSlot>>(
      '/account-slots/available',
      queryParameters: {'include_id': includeId},
      parser: (json) => _parseAccountSlotList(json),
    );
  }

  Future<ApiResponse<AccountSlot>> detail(String id) {
    return _api.get<AccountSlot>(
      '/account-slots/$id',
      parser: (json) => AccountSlot.fromJson(ensureMap(json)),
    );
  }

  /// Gỡ liên kết đơn hàng khỏi slot.
  Future<ApiResponse<AccountSlot>> unlinkOrder(String slotId) {
    return _api.post<AccountSlot>(
      '/account-slots/$slotId/unlink-order',
      data: {},
      parser: (json) => AccountSlot.fromJson(ensureMap(json)),
    );
  }

  /// Tạo access link
  Future<ApiResponse<AccessLink>> createAccessLink(
    String slotId, {
    deactiveExisting = false,
  }) {
    return _api.post<AccessLink>(
      '/account-slots/$slotId/access-links',
      data: {'deactive_existing': deactiveExisting},
      parser: (json) => AccessLink.fromJson(ensureMap(json)),
    );
  }

  /// Lấy lịch sử audit của một slot có phân trang.
  Future<ApiResponse<PaginatedData<Auditable>>> audits(
    int slotId, {
    int page = 1,
    int perPage = 15,
  }) {
    return _api.get<PaginatedData<Auditable>>(
      '/account-slots/$slotId/audits',
      queryParameters: {'page': page, 'per_page': perPage},
      parser: (json) => PaginatedData<Auditable>.fromJson(
        ensureMap(json),
        (item) => Auditable.fromJson(ensureMap(item)),
      ),
    );
  }

  /// Xóa account slot.
  Future<ApiResponse<Map<String, dynamic>?>> delete(String id) {
    return _api.delete<Map<String, dynamic>?>(
      '/account-slots/$id',
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }
}

List<AccountSlot> _parseAccountSlotList(dynamic data) {
  if (data is List) {
    return data
        .map((item) => AccountSlot.fromJson(ensureMap(item)))
        .toList(growable: false);
  }

  if (data is Map) {
    final items = data['items'] ?? data['data'];
    if (items is List) {
      return items
          .map((item) => AccountSlot.fromJson(ensureMap(item)))
          .toList(growable: false);
    }
  }

  return <AccountSlot>[];
}

List<AccountMaster> _parseAccountMasterList(dynamic data) {
  if (data is List) {
    return data
        .map((item) => AccountMaster.fromJson(ensureMap(item)))
        .toList(growable: false);
  }

  if (data is Map) {
    final items = data['items'] ?? data['data'];
    if (items is List) {
      return items
          .map((item) => AccountMaster.fromJson(ensureMap(item)))
          .toList(growable: false);
    }
  }

  return <AccountMaster>[];
}
