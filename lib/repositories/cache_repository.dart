import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/services/supply_service.dart';

/// Centralized Cache Repository for Dropdowns and Master Data
class CacheRepository {
  CacheRepository._internal();
  static final CacheRepository instance = CacheRepository._internal();

  // Default Time-To-Live durations
  static const Duration defaultTtl = Duration(minutes: 10);
  static const Duration shortTtl = Duration(minutes: 3);

  // In-memory caches
  List<Product>? _products;
  DateTime? _productsCacheTime;

  List<Supply>? _supplies;
  DateTime? _suppliesCacheTime;

  List<FinancialTransactionCategory>? _financialCategories;
  DateTime? _financialCategoriesCacheTime;

  List<AccountMaster>? _accountMasters;
  DateTime? _accountMastersCacheTime;

  // Services
  final _productService = ProductService();
  final _supplyService = SupplyService();
  final _financialService = FinancialTransactionCategoryService();
  final _accountMasterService = AccountMasterService();

  // ── Products ─────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts({
    bool forceRefresh = false,
    int perPage = 300,
  }) async {
    final isExpired = _productsCacheTime == null ||
        DateTime.now().difference(_productsCacheTime!) > defaultTtl;

    if (forceRefresh || _products == null || isExpired) {
      final response = await _productService.list(perPage: perPage);
      _products = response.data?.items ?? [];
      _productsCacheTime = DateTime.now();
    }
    return _products!;
  }

  void invalidateProducts() {
    _products = null;
    _productsCacheTime = null;
  }

  // ── Supplies ─────────────────────────────────────────────────────────────
  Future<List<Supply>> getSupplies({
    bool forceRefresh = false,
    int perPage = 300,
  }) async {
    final isExpired = _suppliesCacheTime == null ||
        DateTime.now().difference(_suppliesCacheTime!) > defaultTtl;

    if (forceRefresh || _supplies == null || isExpired) {
      final response = await _supplyService.list(perPage: perPage);
      _supplies = response.data?.items ?? [];
      _suppliesCacheTime = DateTime.now();
    }
    return _supplies!;
  }

  void invalidateSupplies() {
    _supplies = null;
    _suppliesCacheTime = null;
  }

  // ── Financial Transaction Categories ─────────────────────────────────────
  Future<List<FinancialTransactionCategory>> getFinancialCategories({
    bool forceRefresh = false,
  }) async {
    final isExpired = _financialCategoriesCacheTime == null ||
        DateTime.now().difference(_financialCategoriesCacheTime!) > defaultTtl;

    if (forceRefresh || _financialCategories == null || isExpired) {
      final response = await _financialService.list();
      _financialCategories = response.data?.items ?? [];
      _financialCategoriesCacheTime = DateTime.now();
    }
    return _financialCategories!;
  }

  void invalidateFinancialCategories() {
    _financialCategories = null;
    _financialCategoriesCacheTime = null;
  }

  // ── Account Masters ──────────────────────────────────────────────────────
  Future<List<AccountMaster>> getAccountMasters({
    bool forceRefresh = false,
    int perPage = 300,
  }) async {
    final isExpired = _accountMastersCacheTime == null ||
        DateTime.now().difference(_accountMastersCacheTime!) > shortTtl;

    if (forceRefresh || _accountMasters == null || isExpired) {
      final response = await _accountMasterService.list(perPage: perPage);
      _accountMasters = response.data?.items ?? [];
      _accountMastersCacheTime = DateTime.now();
    }
    return _accountMasters!;
  }

  void invalidateAccountMasters() {
    _accountMasters = null;
    _accountMastersCacheTime = null;
  }

  // ── Clear All ────────────────────────────────────────────────────────────
  void invalidateAll() {
    invalidateProducts();
    invalidateSupplies();
    invalidateFinancialCategories();
    invalidateAccountMasters();
  }
}
