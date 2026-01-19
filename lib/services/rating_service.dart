import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class RatingService {
  RatingService() : _api = ApiService();

  final ApiService _api;

  /// Get paginated list of ratings with optional filters
  ///
  /// [approved] - Filter by approval status (true/false)
  /// [page] - Page number for pagination (default: 1)
  /// [perPage] - Number of items per page (default: 10)
  Future<ApiResponse<PaginatedData<Rating>>> list({
    bool? approved,
    int page = 1,
    int perPage = 10,
  }) {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'per_page': perPage,
    };

    if (approved != null) {
      queryParameters['approved'] = approved;
    }

    return _api.get<PaginatedData<Rating>>(
      '/rating',
      queryParameters: queryParameters,
      parser: (json) => PaginatedData<Rating>.fromJson(
        ensureMap(json),
        (item) => Rating.fromJson(ensureMap(item)),
      ),
    );
  }

  /// Get a specific rating by ID
  ///
  /// [id] - The ID of the rating to retrieve
  Future<ApiResponse<Rating>> show(int id) {
    return _api.get<Rating>(
      '/rating/$id',
      parser: (json) => Rating.fromJson(ensureMap(json)),
    );
  }

  /// Approve a rating
  ///
  /// [id] - The ID of the rating to approve
  Future<ApiResponse<Rating>> approve(int id) {
    return _api.post<Rating>(
      '/rating/$id/approve',
      parser: (json) => Rating.fromJson(ensureMap(json)),
    );
  }

  /// Reject/unapprove a rating
  ///
  /// [id] - The ID of the rating to reject
  Future<ApiResponse<Rating>> reject(int id) {
    return _api.post<Rating>(
      '/rating/$id/reject',
      parser: (json) => Rating.fromJson(ensureMap(json)),
    );
  }

  /// Delete a rating
  ///
  /// [id] - The ID of the rating to delete
  Future<ApiResponse<void>> delete(int id) {
    return _api.delete<void>('/rating/$id', parser: (_) {});
  }
}
