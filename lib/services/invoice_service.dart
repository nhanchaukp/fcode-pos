import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api_service.dart';
import 'package:fcode_pos/utils/extensions.dart';

class InvoiceService {
  InvoiceService() : _api = ApiService();

  final ApiService _api;

  // ── Invoices ────────────────────────────────────────────────────────────────

  Future<ApiResponse<PaginatedData<Invoice>>> listInvoices({
    int page = 1,
    int perPage = 10,
    String? status,
    String? search,
  }) {
    return _api.get<PaginatedData<Invoice>>(
      '/invoice/sepay/invoices',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      parser: (json) => _parsePaginatedInvoices(ensureMap(json)),
    );
  }

  Future<ApiResponse<Invoice>> getInvoice(String referenceCode) {
    return _api.get<Invoice>(
      '/invoice/sepay/invoices/$referenceCode',
      parser: (json) => Invoice.fromJson(ensureMap(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> deleteDraftInvoice(
    String referenceCode,
  ) {
    final ref = Uri.encodeComponent(referenceCode);
    return _api.post<Map<String, dynamic>?>(
      '/invoice/sepay/delete/$ref',
      parser: (json) => json == null ? null : ensureMap(json),
    );
  }

  // ── Provider accounts ───────────────────────────────────────────────────────

  Future<ApiResponse<PaginatedData<InvoiceProviderAccount>>> listProviders({
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<PaginatedData<InvoiceProviderAccount>>(
      '/invoice/sepay/provider-accounts',
      queryParameters: {'page': page, 'per_page': perPage},
      parser: (json) => _parsePaginatedProviders(ensureMap(json)),
    );
  }

  Future<ApiResponse<InvoiceProviderAccount>> getProvider(String id) {
    return _api.get<InvoiceProviderAccount>(
      '/invoice/sepay/provider-accounts/$id',
      parser: (json) => InvoiceProviderAccount.fromJson(ensureMap(json)),
    );
  }

  // ── Quota ───────────────────────────────────────────────────────────────────

  Future<ApiResponse<InvoiceQuota>> getQuota() {
    return _api.get<InvoiceQuota>(
      '/invoice/sepay/quota',
      parser: (json) => InvoiceQuota.fromJson(ensureMap(json)),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// The Sepay API uses `paging` (with `page_count`) instead of `pagination`
  /// (with `last_page`). This normalises the response before handing it off
  /// to [PaginatedData.fromJson].
  static PaginatedData<Invoice> _parsePaginatedInvoices(
    Map<String, dynamic> json,
  ) {
    return PaginatedData<Invoice>.fromJson(
      _normalizePaging(json),
      (item) => Invoice.fromJson(ensureMap(item)),
    );
  }

  static PaginatedData<InvoiceProviderAccount> _parsePaginatedProviders(
    Map<String, dynamic> json,
  ) {
    return PaginatedData<InvoiceProviderAccount>.fromJson(
      _normalizePaging(json),
      (item) => InvoiceProviderAccount.fromJson(ensureMap(item)),
    );
  }

  /// Copies the `paging` block into `pagination` using the field names that
  /// [Pagination.fromJson] expects (`last_page` ← `page_count`).
  static Map<String, dynamic> _normalizePaging(Map<String, dynamic> json) {
    final paging = ensureMap(json['paging']);
    return {
      ...json,
      'pagination': {
        'per_page': paging['per_page'],
        'total': paging['total'],
        'current_page': paging['current_page'],
        'last_page': paging['page_count'],
      },
    };
  }
}
