import 'package:intl/intl.dart';

class OrderListFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final int perPage;
  final String status;
  final String userId;
  final String search;
  final int? productId;

  const OrderListFilter({
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.perPage = 20,
    this.status = '',
    this.userId = '',
    this.search = '',
    this.productId,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'date_from': fromDate != null
          ? DateFormat('yyyy-MM-dd').format(fromDate!)
          : null,
      'date_to': toDate != null
          ? DateFormat('yyyy-MM-dd').format(toDate!)
          : null,
      'page': page,
      'per_page': perPage,
      'status': status,
      'user_id': userId,
      'search': search,
      'product_id': productId,
    };
  }

  OrderListFilter copyWith({
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
    int? page,
    int? perPage,
    String? status,
    String? userId,
    String? search,
    int? Function()? productId,
  }) {
    return OrderListFilter(
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      search: search ?? this.search,
      productId: productId != null ? productId() : this.productId,
    );
  }
}
