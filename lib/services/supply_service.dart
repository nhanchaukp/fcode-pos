import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';

class SupplyService {
  final _api = ApiService().dio;

  Future<List<Supply>> list() async {
    final res = await _api.get('/supply');

    // API returns {"data": [...]} structure
    if (res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .map((item) => Supply.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Fallback for direct list response
    if (res.data is List) {
      return (res.data as List)
          .map((item) => Supply.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<Supply> detail(String id) async {
    final res = await _api.get('/supply/$id');
    return Supply.fromJson(res.data);
  }
}
