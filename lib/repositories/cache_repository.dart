import 'package:flutter/foundation.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/services/supply_service.dart';

/// Centralized Cache Repository for Dropdowns and Master Data
class CacheRepository {
  CacheRepository._internal();
  static final CacheRepository instance = CacheRepository._internal();

  // Default Time-To-Live durations (24 hours)
  static const Duration defaultTtl = Duration(hours: 24);

  // In-memory caches
  List<Product>? _products;
  DateTime? _productsCacheTime;

  List<Supply>? _supplies;
  DateTime? _suppliesCacheTime;

  List<AccountMaster>? _accountMasters;
  DateTime? _accountMastersCacheTime;

  // Services
  final _productService = ProductService();
  final _supplyService = SupplyService();
  final _accountMasterService = AccountMasterService();

  // ── Products ─────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts({
    bool forceRefresh = false,
    int perPage = 200,
  }) async {
    final isExpired = _productsCacheTime == null ||
        DateTime.now().difference(_productsCacheTime!) > defaultTtl;

    if (forceRefresh || _products == null || _products!.isEmpty || isExpired) {
      try {
        final response = await _productService.list(perPage: perPage);
        final items = response.data?.items ?? [];
        if (items.isNotEmpty) {
          _products = items;
          _productsCacheTime = DateTime.now();
        } else if (_products == null) {
          _products = items;
        }
      } catch (e) {
        debugPrint('Error fetching products in CacheRepository: $e');
        if (_products == null) _products = [];
      }
    }
    return _products ?? [];
  }

  void invalidateProducts() {
    _products = null;
    _productsCacheTime = null;
  }

  // ── Supplies ─────────────────────────────────────────────────────────────
  Future<List<Supply>> getSupplies({
    bool forceRefresh = false,
    int perPage = 100,
  }) async {
    final isExpired = _suppliesCacheTime == null ||
        DateTime.now().difference(_suppliesCacheTime!) > defaultTtl;

    if (forceRefresh || _supplies == null || _supplies!.isEmpty || isExpired) {
      try {
        final response = await _supplyService.list(perPage: perPage);
        final items = response.data?.items ?? [];
        if (items.isNotEmpty) {
          _supplies = items;
          _suppliesCacheTime = DateTime.now();
        } else if (_supplies == null) {
          _supplies = items;
        }
      } catch (e) {
        debugPrint('Error fetching supplies in CacheRepository: $e');
        if (_supplies == null) _supplies = [];
      }
    }
    return _supplies ?? [];
  }

  void invalidateSupplies() {
    _supplies = null;
    _suppliesCacheTime = null;
  }

  // ── Account Masters ──────────────────────────────────────────────────────
  Future<List<AccountMaster>> getAccountMasters({
    bool forceRefresh = false,
    bool? isActive = true,
  }) async {
    final isExpired = _accountMastersCacheTime == null ||
        DateTime.now().difference(_accountMastersCacheTime!) > defaultTtl;

    if (forceRefresh || _accountMasters == null || _accountMasters!.isEmpty || isExpired) {
      try {
        final response = await _accountMasterService.list(isActive: isActive);
        final items = response.data ?? [];
        if (items.isNotEmpty) {
          _accountMasters = items;
          _accountMastersCacheTime = DateTime.now();
        } else if (_accountMasters == null) {
          _accountMasters = items;
        }
      } catch (e) {
        debugPrint('Error fetching account masters in CacheRepository: $e');
        if (_accountMasters == null) _accountMasters = [];
      }
    }
    return _accountMasters ?? [];
  }

  void invalidateAccountMasters() {
    _accountMasters = null;
    _accountMastersCacheTime = null;
  }

  // ── Clear All ────────────────────────────────────────────────────────────
  void invalidateAll() {
    invalidateProducts();
    invalidateSupplies();
    invalidateAccountMasters();
  }
}
