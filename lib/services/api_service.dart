import 'package:fcode_pos/services/api/base_api_service.dart';

class ApiService extends BaseApiService {
  factory ApiService() => _instance;

  ApiService._internal() : super();

  static final ApiService _instance = ApiService._internal();
}
