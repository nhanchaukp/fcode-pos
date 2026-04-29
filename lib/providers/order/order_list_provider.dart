import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/order/order_filter_provider.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderListState {
  final List<Order> orders;
  final Pagination? pagination;
  final OrderSummary? summary;

  const OrderListState({
    this.orders = const [],
    this.pagination,
    this.summary,
  });

  OrderListState copyWith({
    List<Order>? orders,
    Pagination? Function()? pagination,
    OrderSummary? Function()? summary,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      pagination: pagination != null ? pagination() : this.pagination,
      summary: summary != null ? summary() : this.summary,
    );
  }
}

final orderListProvider =
    AsyncNotifierProvider<OrderListNotifier, OrderListState>(
  OrderListNotifier.new,
);

class OrderListNotifier extends AsyncNotifier<OrderListState> {
  final _service = OrderService();

  @override
  Future<OrderListState> build() async {
    final filter = ref.watch(orderFilterProvider);

    final results = await Future.wait([
      _service.list(
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        page: filter.page,
        perPage: 20,
        status: filter.status?.value ?? '',
        userId: filter.user?.id.toString() ?? '',
      ),
      _service.summary(
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        status: filter.status?.value ?? '',
        userId: filter.user?.id.toString() ?? '',
      ),
    ]);

    final listResponse = results[0] as ApiResponse<PaginatedData<Order>>;
    final summaryResponse = results[1] as ApiResponse<OrderSummary>;

    return OrderListState(
      orders: listResponse.data?.items ?? [],
      pagination: listResponse.data?.pagination,
      summary: summaryResponse.data,
    );
  }

  /// Prepend a newly created order to the list (optimistic).
  /// Triggers a background refetch to sync summary + pagination.
  void addOrder(Order order) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(orders: [order, ...current.orders]),
      );
    }
    ref.invalidateSelf();
  }

  /// Replace an order in the list by id (optimistic).
  void updateOrder(Order updated) {
    final current = state.value;
    if (current == null) return;

    final idx = current.orders.indexWhere((o) => o.id == updated.id);
    if (idx == -1) return;

    final newList = List<Order>.of(current.orders);
    newList[idx] = updated;
    state = AsyncData(current.copyWith(orders: newList));
  }
}
