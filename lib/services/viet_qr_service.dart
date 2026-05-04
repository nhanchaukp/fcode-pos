import 'package:dio/dio.dart';
import 'package:fcode_pos/models/viet_qr_business_info.dart';

class VietQrService {
  VietQrService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.vietqr.io/v2',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      );

  static final VietQrService _instance = VietQrService._internal();
  factory VietQrService() => _instance;

  final Dio _dio;

  /// Tra cứu thông tin doanh nghiệp theo mã số thuế.
  /// Trả về [VietQrBusinessInfo] nếu thành công, null nếu không tìm thấy.
  Future<VietQrBusinessInfo?> lookupByTaxCode(String taxCode) async {
    final trimmed = taxCode.trim();
    if (trimmed.isEmpty) return null;

    try {
      final response = await _dio.get<dynamic>('/business/$trimmed');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) return null;

      final result = VietQrBusinessResponse.fromJson(raw);
      return result.isSuccess ? result.data : null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
