import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:flutter_riverpod/legacy.dart';

class OrderFilter {
  final DateTime fromDate;
  final DateTime toDate;
  final OrderStatus? status;
  final User? user;
  final Product? product;
  final int page;

  const OrderFilter({
    required this.fromDate,
    required this.toDate,
    this.status,
    this.user,
    this.product,
    this.page = 1,
  });

  OrderFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    OrderStatus? Function()? status,
    User? Function()? user,
    Product? Function()? product,
    int? page,
  }) {
    return OrderFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status != null ? status() : this.status,
      user: user != null ? user() : this.user,
      product: product != null ? product() : this.product,
      page: page ?? this.page,
    );
  }

  OrderListFilter toDto({int perPage = 20, String search = ''}) {
    return OrderListFilter(
      fromDate: fromDate,
      toDate: toDate,
      page: page,
      perPage: perPage,
      status: status?.value ?? '',
      userId: user?.id.toString() ?? '',
      search: search,
      productId: product?.id,
    );
  }

  bool get hasActiveFilters =>
      (status != null && status != OrderStatus.all) ||
      user != null ||
      product != null;
}

final orderFilterProvider = StateProvider<OrderFilter>((ref) {
  final now = DateTime.now();
  return OrderFilter(
    fromDate: now,
    toDate: now,
    status: OrderStatus.all,
  );
});
