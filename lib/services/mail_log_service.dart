import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class MailLogService {
  MailLogService() : _api = ApiService();

  final ApiService _api;

  /// Get paginated list of mail logs with optional filters
  ///
  /// [status] - Filter by mail status (e.g., "sent", "pending", "failed")
  /// [recipient] - Filter by recipient email address
  /// [subject] - Search by subject (partial match)
  /// [page] - Page number for pagination (default: 1)
  /// [perPage] - Number of items per page (default: 15)
  Future<ApiResponse<PaginatedData<MailLog>>> list({
    String? status,
    String? recipient,
    String? subject,
    int page = 1,
    int perPage = 15,
  }) {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'per_page': perPage,
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (recipient != null && recipient.isNotEmpty) {
      queryParameters['recipient'] = recipient;
    }
    if (subject != null && subject.isNotEmpty) {
      queryParameters['subject'] = subject;
    }

    return _api.get<PaginatedData<MailLog>>(
      '/mail-log',
      queryParameters: queryParameters,
      parser: (json) => PaginatedData<MailLog>.fromJson(
        ensureMap(json),
        (item) => MailLog.fromJson(ensureMap(item)),
      ),
    );
  }

  /// Get a specific mail log by ID
  ///
  /// [id] - The ID of the mail log to retrieve
  Future<ApiResponse<MailLog>> show(int id) {
    return _api.get<MailLog>(
      '/mail-log/$id',
      parser: (json) => MailLog.fromJson(ensureMap(json)),
    );
  }
}
