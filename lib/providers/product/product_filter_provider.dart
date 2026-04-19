import 'package:flutter_riverpod/legacy.dart';

class ProductFilter {
  final String search;
  final int page;

  const ProductFilter({this.search = '', this.page = 1});

  ProductFilter copyWith({
    String? search,
    int? page,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

final productFilterProvider = StateProvider<ProductFilter>(
  (ref) => const ProductFilter(),
);
