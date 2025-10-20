import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class AccountSlotService {
  final _api = ApiService().dio;

  Future<List<AccountSlot>> list() async {
    final res = await _api.get('/account-slots');

    // API trả về format: { "data": [...] }
    if (res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .map((item) => AccountSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Fallback: nếu API trả về trực tiếp là List
    if (res.data is List) {
      return (res.data as List)
          .map((item) => AccountSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<List<AccountSlot>> available() async {
    final res = await _api.get('/account-slots/available');

    // API trả về format: { "data": [...] }
    if (res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .map((item) => AccountSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Fallback: nếu API trả về trực tiếp là List
    if (res.data is List) {
      return (res.data as List)
          .map((item) => AccountSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<AccountSlot> detail(String id) async {
    final res = await _api.get('/account-slots/$id');
    return AccountSlot.fromJson(res.data);
  }
}
