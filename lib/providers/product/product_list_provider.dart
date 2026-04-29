import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/product/product_filter_provider.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, PaginatedData<Product>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AsyncNotifier<PaginatedData<Product>> {
  final _service = ProductService();

  @override
  Future<PaginatedData<Product>> build() async {
    final filter = ref.watch(productFilterProvider);

    final response = await _service.list(
      search: filter.search,
      page: filter.page,
      perPage: 20,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Không thể tải danh sách sản phẩm');
    }

    return response.data!;
  }
}
