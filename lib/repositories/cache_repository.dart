import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/services/supply_service.dart';

/// Centralized Cache Repository backed by Hive with In-Memory acceleration
class CacheRepository {
  CacheRepository._internal();
  static final CacheRepository instance = CacheRepository._internal();

  // Default Time-To-Live durations (24 hours)
  static const Duration defaultTtl = Duration(hours: 24);
  static const String _boxName = 'app_cache_box';

  // In-memory caches (L1)
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

  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  // ── Products ─────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts({
    bool forceRefresh = false,
    int perPage = 200,
  }) async {
    // 1. Kiểm tra RAM Cache (L1)
    final isMemoryValid = !forceRefresh &&
        _products != null &&
        _products!.isNotEmpty &&
        _productsCacheTime != null &&
        DateTime.now().difference(_productsCacheTime!) <= defaultTtl;

    if (isMemoryValid) {
      return _products!;
    }

    // 2. Kiểm tra Hive Storage (L2) nếu không force refresh
    if (!forceRefresh) {
      try {
        final box = await _getBox();
        final cached = box.get('products');
        if (cached is Map) {
          final timeStr = cached['time']?.toString();
          final rawList = cached['data'] as List?;
          if (timeStr != null && rawList != null) {
            final cacheTime = DateTime.tryParse(timeStr);
            if (cacheTime != null &&
                DateTime.now().difference(cacheTime) <= defaultTtl) {
              _products = rawList
                  .whereType<Map>()
                  .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              _productsCacheTime = cacheTime;
              if (_products!.isNotEmpty) {
                return _products!;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error reading products from Hive cache: $e');
      }
    }

    // 3. Gọi API khi chưa có cache, hết hạn hoặc forceRefresh
    try {
      final response = await _productService.list(perPage: perPage);
      final items = response.data?.items ?? [];
      if (items.isNotEmpty) {
        _products = items;
        _productsCacheTime = DateTime.now();

        // Lưu xuống Hive Storage (L2)
        try {
          final box = await _getBox();
          await box.put('products', {
            'time': _productsCacheTime!.toIso8601String(),
            'data': items.map((e) => e.toMap()).toList(),
          });
        } catch (e) {
          debugPrint('Error saving products to Hive cache: $e');
        }
      } else {
        _products ??= items;
      }
    } catch (e) {
      debugPrint('Error fetching products in CacheRepository: $e');
      _products ??= [];
    }
    return _products ?? [];
  }

  Future<void> invalidateProducts() async {
    _products = null;
    _productsCacheTime = null;
    try {
      final box = await _getBox();
      await box.delete('products');
    } catch (e) {
      debugPrint('Error invalidating products in Hive: $e');
    }
  }

  // ── Supplies ─────────────────────────────────────────────────────────────
  Future<List<Supply>> getSupplies({
    bool forceRefresh = false,
    int perPage = 100,
  }) async {
    // 1. Kiểm tra RAM Cache (L1)
    final isMemoryValid = !forceRefresh &&
        _supplies != null &&
        _supplies!.isNotEmpty &&
        _suppliesCacheTime != null &&
        DateTime.now().difference(_suppliesCacheTime!) <= defaultTtl;

    if (isMemoryValid) {
      return _supplies!;
    }

    // 2. Kiểm tra Hive Storage (L2) nếu không force refresh
    if (!forceRefresh) {
      try {
        final box = await _getBox();
        final cached = box.get('supplies');
        if (cached is Map) {
          final timeStr = cached['time']?.toString();
          final rawList = cached['data'] as List?;
          if (timeStr != null && rawList != null) {
            final cacheTime = DateTime.tryParse(timeStr);
            if (cacheTime != null &&
                DateTime.now().difference(cacheTime) <= defaultTtl) {
              _supplies = rawList
                  .whereType<Map>()
                  .map((e) => Supply.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              _suppliesCacheTime = cacheTime;
              if (_supplies!.isNotEmpty) {
                return _supplies!;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error reading supplies from Hive cache: $e');
      }
    }

    // 3. Gọi API khi chưa có cache, hết hạn hoặc forceRefresh
    try {
      final response = await _supplyService.list(perPage: perPage);
      final items = response.data?.items ?? [];
      if (items.isNotEmpty) {
        _supplies = items;
        _suppliesCacheTime = DateTime.now();

        // Lưu xuống Hive Storage (L2)
        try {
          final box = await _getBox();
          await box.put('supplies', {
            'time': _suppliesCacheTime!.toIso8601String(),
            'data': items.map((e) => e.toMap()).toList(),
          });
        } catch (e) {
          debugPrint('Error saving supplies to Hive cache: $e');
        }
      } else {
        _supplies ??= items;
      }
    } catch (e) {
      debugPrint('Error fetching supplies in CacheRepository: $e');
      _supplies ??= [];
    }
    return _supplies ?? [];
  }

  Future<void> invalidateSupplies() async {
    _supplies = null;
    _suppliesCacheTime = null;
    try {
      final box = await _getBox();
      await box.delete('supplies');
    } catch (e) {
      debugPrint('Error invalidating supplies in Hive: $e');
    }
  }

  // ── Account Masters ──────────────────────────────────────────────────────
  Future<List<AccountMaster>> getAccountMasters({
    bool forceRefresh = false,
    bool? isActive = true,
  }) async {
    final cacheKey = 'account_masters_${isActive ?? 'all'}';

    // 1. Kiểm tra RAM Cache (L1)
    final isMemoryValid = !forceRefresh &&
        _accountMasters != null &&
        _accountMasters!.isNotEmpty &&
        _accountMastersCacheTime != null &&
        DateTime.now().difference(_accountMastersCacheTime!) <= defaultTtl;

    if (isMemoryValid) {
      return _accountMasters!;
    }

    // 2. Kiểm tra Hive Storage (L2) nếu không force refresh
    if (!forceRefresh) {
      try {
        final box = await _getBox();
        final cached = box.get(cacheKey);
        if (cached is Map) {
          final timeStr = cached['time']?.toString();
          final rawList = cached['data'] as List?;
          if (timeStr != null && rawList != null) {
            final cacheTime = DateTime.tryParse(timeStr);
            if (cacheTime != null &&
                DateTime.now().difference(cacheTime) <= defaultTtl) {
              _accountMasters = rawList
                  .whereType<Map>()
                  .map((e) => AccountMaster.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              _accountMastersCacheTime = cacheTime;
              if (_accountMasters!.isNotEmpty) {
                return _accountMasters!;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error reading account masters from Hive cache: $e');
      }
    }

    // 3. Gọi API khi chưa có cache, hết hạn hoặc forceRefresh
    try {
      final response = await _accountMasterService.list(isActive: isActive);
      final items = response.data ?? [];
      if (items.isNotEmpty) {
        _accountMasters = items;
        _accountMastersCacheTime = DateTime.now();

        // Lưu xuống Hive Storage (L2)
        try {
          final box = await _getBox();
          await box.put(cacheKey, {
            'time': _accountMastersCacheTime!.toIso8601String(),
            'data': items.map((e) => e.toMap()).toList(),
          });
        } catch (e) {
          debugPrint('Error saving account masters to Hive cache: $e');
        }
      } else {
        _accountMasters ??= items;
      }
    } catch (e) {
      debugPrint('Error fetching account masters in CacheRepository: $e');
      _accountMasters ??= [];
    }
    return _accountMasters ?? [];
  }

  Future<void> invalidateAccountMasters() async {
    _accountMasters = null;
    _accountMastersCacheTime = null;
    try {
      final box = await _getBox();
      await box.delete('account_masters_true');
      await box.delete('account_masters_false');
      await box.delete('account_masters_all');
    } catch (e) {
      debugPrint('Error invalidating account masters in Hive: $e');
    }
  }

  // ── Clear All ────────────────────────────────────────────────────────────
  Future<void> invalidateAll() async {
    await invalidateProducts();
    await invalidateSupplies();
    await invalidateAccountMasters();
  }
}
