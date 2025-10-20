import 'package:fcode_pos/models.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/services/api_service.dart';

class ProductSupplyService {
  final _api = ApiService().dio;

  /// Get best price for a product (lowest price from all supplies)
  Future<ProductSupply?> bestPrice(int productId, {int? supplyId}) async {
    try {
      final res = await _api.get(
        '/product-supply/best-price/$productId',
        queryParameters: {'supply_id': supplyId},
      );

      if (res.data == null) {
        return null;
      }

      // API returns {"data": [...]} or {"data": {}} structure
      if (res.data is Map) {
        final data = res.data['data'];

        // If data is a list, get the first item
        if (data is List) {
          if (data.isEmpty) {
            return null;
          }
          return ProductSupply.fromJson(data[0] as Map<String, dynamic>);
        }

        // If data is a map, use it directly
        if (data is Map) {
          return ProductSupply.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting best price for product $productId: $e');
      return null;
    }
  }

  /// Get a specific product-supply mapping
  Future<ProductSupply?> detail(int id) async {
    try {
      final res = await _api.get('/product-supply/$id');

      if (res.data == null) {
        return null;
      }

      // API returns {"data": {...}} structure
      if (res.data is Map) {
        final data = res.data['data'] ?? res.data;
        return ProductSupply.fromJson(data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting product supply map $id: $e');
      return null;
    }
  }

  /// List all product-supply mappings
  Future<List<ProductSupply>> list() async {
    try {
      final res = await _api.get('/product-supply');

      // API returns {"data": [...]} structure
      if (res.data is Map && res.data['data'] is List) {
        return (res.data['data'] as List)
            .map((item) => ProductSupply.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Fallback for direct list response
      if (res.data is List) {
        return (res.data as List)
            .map((item) => ProductSupply.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error listing product supply maps: $e');
      return [];
    }
  }
}
