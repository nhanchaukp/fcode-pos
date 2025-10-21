import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/screens/order_detail_screen.dart';
import 'package:fcode_pos/ui/components/order_status_badge.dart';

class OrderListComponent extends StatefulWidget {
  /// Ngày bắt đầu filter (mặc định: 7 ngày trước)
  final DateTime? fromDate;

  /// Ngày kết thúc filter (mặc định: hôm nay)
  final DateTime? toDate;

  /// Trạng thái đơn hàng (mặc định: 'new')
  final String status;

  /// Số mục trên mỗi trang (mặc định: 20)
  final int perPage;

  /// ID người dùng (mặc định: rỗng - tất cả người dùng)
  final String? userId;

  /// Callback khi click vào đơn hàng
  final Function(Order)? onOrderTap;

  /// Callback khi pagination thay đổi
  final Function(int currentPage, int totalPages)? onPaginationChanged;

  /// Trang hiện tại từ parent (để đồng bộ với BottomAppBar)
  final int? currentPage;

  /// Callback khi loading state thay đổi
  final Function(bool isLoading)? onLoadingChanged;

  /// Callback khi total items thay đổi
  final Function(int total)? onTotalChanged;

  const OrderListComponent({
    super.key,
    this.fromDate,
    this.toDate,
    this.status = '',
    this.perPage = 20,
    this.userId,
    this.onOrderTap,
    this.onPaginationChanged,
    this.currentPage,
    this.onLoadingChanged,
    this.onTotalChanged,
  });

  @override
  State<OrderListComponent> createState() => _OrderListComponentState();
}

class _OrderListComponentState extends State<OrderListComponent> {
  late OrderService _orderService;
  ApiResponse<PaginatedData<Order>>? _orderPageable;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _loadOrders();
  }

  @override
  void didUpdateWidget(OrderListComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Kiểm tra nếu page từ parent thay đổi
    if (widget.currentPage != null &&
        oldWidget.currentPage != widget.currentPage &&
        widget.currentPage != _currentPage) {
      _loadOrders(page: widget.currentPage!);
      return;
    }

    // Kiểm tra xem params có thay đổi không
    if (oldWidget.fromDate != widget.fromDate ||
        oldWidget.toDate != widget.toDate ||
        oldWidget.status != widget.status ||
        oldWidget.userId != widget.userId) {
      // Reset về trang 1 khi filter thay đổi
      _currentPage = 1;
      _loadOrders(page: 1);
    }
  }

  Future<void> _loadOrders({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    // Notify parent về loading state
    widget.onLoadingChanged?.call(true);

    try {
      final fromDate =
          widget.fromDate ?? DateTime.now().subtract(Duration(days: 7));
      final toDate = widget.toDate ?? DateTime.now();

      final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd').format(toDate);

      final result = await _orderService.list(
        fromDateStr,
        toDateStr,
        page: page,
        perPage: widget.perPage,
        status: widget.status,
        userId: widget.userId ?? '',
      );

      if (!mounted) return;
      final pagination = result.data?.pagination;

      setState(() {
        _orderPageable = result;
        _error = null;
        _isLoading = false;
      });

      // Notify parent về pagination changes
      if (widget.onPaginationChanged != null && pagination != null) {
        widget.onPaginationChanged!(
          pagination.currentPage,
          pagination.lastPage,
        );
      }

      // Notify parent về total items
      if (widget.onTotalChanged != null && pagination != null) {
        widget.onTotalChanged!(pagination.total);
      }

      // Notify parent loading completed
      widget.onLoadingChanged?.call(false);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      // Notify parent loading completed with error
      widget.onLoadingChanged?.call(false);
    }
  }

  void _onOrderTap(Order order) {
    if (widget.onOrderTap != null) {
      widget.onOrderTap!(order);
    } else {
      // Chuyển sang màn hình chi tiết
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: order.id.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orderPageable == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOrders(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final orders = _orderPageable?.data?.items ?? [];
    if (_orderPageable == null || orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Không có đơn hàng',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadOrders(page: _currentPage),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderTile(order);
              },
            ),
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildOrderTile(Order order) {
    final rawCustomerName = order.user?.name;
    final customerName = rawCustomerName?.trim();
    final rawCustomerEmail = order.user?.email;
    final customerEmail = rawCustomerEmail?.trim();
    final createdAtLabel = order.createdAt != null
        ? DateHelper.formatDateTime(order.createdAt!)
        : '—';
    final totalFormatted = CurrencyHelper.formatCurrency(order.total);
    final itemCount = order.itemCount;
    final productCountLabel = itemCount > 0
        ? '$itemCount sản phẩm'
        : 'Chưa có sản phẩm';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _onOrderTap(order),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName?.isNotEmpty == true
                              ? customerName!
                              : 'Khách hàng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (customerEmail?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              customerEmail!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant
                                    .applyOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  OrderStatusBadge(
                    status: order.status,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            productCountLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          createdAtLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.applyOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  totalFormatted,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final pagination = _orderPageable?.data?.pagination;
    if (pagination == null || pagination.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text(
            'Trang ${pagination.currentPage}/${pagination.lastPage}',
            style: textStyle,
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: pagination.currentPage > 1
                ? () => _loadOrders(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: pagination.currentPage < pagination.lastPage
                ? () => _loadOrders(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}
