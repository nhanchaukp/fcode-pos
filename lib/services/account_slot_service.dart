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
  }) {
    return _api.get<List<AccountMaster>>(
      '/account-slots',
      queryParameters: {
        if (accountMasterId != null) 'account_master_id': accountMasterId,
        if (isActive != null) 'is_active': isActive,
        if (serviceType != null) 'service_type': serviceType.toLowerCase(),
        if (search != null) 'search': search,
        if (daysRemaining != null) 'days_remaining': daysRemaining,
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

  /// Cập nhật thông tin slot (tên, pin).
  Future<ApiResponse<AccountSlot>> updateSlot(
    String slotId, {
    required String name,
    String? pin,
  }) {
    return _api.put<AccountSlot>(
      '/account-slots/$slotId',
      data: {
        'name': name,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
      parser: (json) => AccountSlot.fromJson(ensureMap(json)),
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
