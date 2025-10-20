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
  late AuthService _orderService;
  OrderPageable? _orderPageable;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _orderService = AuthService();
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

      setState(() {
        _orderPageable = result;
        _isLoading = false;
      });

      // Notify parent về pagination changes
      if (widget.onPaginationChanged != null && result.meta != null) {
        widget.onPaginationChanged!(
          result.meta!.currentPage,
          result.meta!.lastPage,
        );
      }

      // Notify parent về total items
      if (widget.onTotalChanged != null && result.meta != null) {
        widget.onTotalChanged!(result.meta!.total);
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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

    if (_orderPageable?.data.isEmpty ?? true) {
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
              itemCount: _orderPageable!.data.length,
              itemBuilder: (context, index) {
                final order = _orderPageable!.data[index];
                return _buildOrderTile(order);
              },
            ),
          ),
        ),
        // Không hiển thị pagination controls ở đây nữa vì đã chuyển lên BottomAppBar
      ],
    );
  }

  Widget _buildOrderTile(Order order) {
    return Card.filled(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '#${order.id}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                order.user?.name ?? 'Khách hàng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OrderStatusBadge(
                        status: order.status,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.applyOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Price info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyHelper.formatCurrency(order.total),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right column: Dates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateHelper.formatDateTime(order.createdAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.applyOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.note != null && order.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ghi chú: ${order.note}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _onOrderTap(order),
      ),
    );
  }
}
