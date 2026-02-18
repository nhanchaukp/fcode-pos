import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/ui/components/order_status_badge.dart';

/// Chế độ hiển thị danh sách đơn hàng.
enum OrderListViewMode {
  /// Đầy đủ: mã đơn, trạng thái, khách hàng, sản phẩm, ngày giờ, tổng tiền.
  full,

  /// Rút gọn: chỉ mã đơn, trạng thái, ngày giờ, số tiền.
  compact,
}

class OrderListComponent extends StatelessWidget {
  /// Danh sách đơn hàng
  final List<Order> orders;

  /// Trạng thái loading
  final bool isLoading;

  /// Lỗi (nếu có)
  final String? error;

  /// Trang hiện tại
  final int currentPage;

  /// Tổng số trang
  final int totalPages;

  /// Callback khi thay đổi trang
  final Function(int page)? onPageChanged;

  /// Callback khi click vào đơn hàng
  final Function(Order)? onOrderTap;

  /// Callback khi retry sau lỗi
  final VoidCallback? onRetry;

  /// Chế độ xem: đầy đủ hoặc rút gọn
  final OrderListViewMode viewMode;

  const OrderListComponent({
    super.key,
    required this.orders,
    required this.isLoading,
    this.error,
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
    this.onOrderTap,
    this.onRetry,
    this.viewMode = OrderListViewMode.full,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
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

    final completedCount =
        orders.where((o) => o.status == 'complete').length;
    final paymentSuccessCount =
        orders.where((o) => o.status == 'payment_success').length;
    final totalOrders = orders.length;
    final hasPagination = totalPages > 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 1 + orders.length + (hasPagination ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsCard(
            context,
            colorScheme,
            completedCount: completedCount,
            paymentSuccessCount: paymentSuccessCount,
            totalOrders: totalOrders,
          );
        }
        if (index <= orders.length) {
          final order = orders[index - 1];
          return viewMode == OrderListViewMode.compact
              ? _buildOrderTileCompact(order, colorScheme)
              : _buildOrderTile(order, colorScheme);
        }
        return _buildPaginationControls(context, colorScheme);
      },
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required int completedCount,
    required int paymentSuccessCount,
    required int totalOrders,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.applyOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Hoàn thành $completedCount/$totalOrders',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: colorScheme.outlineVariant.applyOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Đã thanh toán: $paymentSuccessCount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOrderTap(BuildContext context, Order order) {
    if (onOrderTap != null) {
      onOrderTap!(order);
    } else {
      // Chuyển sang màn hình chi tiết
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: order.id.toString()),
        ),
      );
    }
  }

  Widget _buildOrderTile(Order order, ColorScheme colorScheme) {
    final productNames = order.items
        .map((item) => item.product?.name ?? 'Sản phẩm #${item.productId}')
        .take(3)
        .toList();

    final hasMoreProducts = order.items.length > 3;

    return Builder(
      builder: (context) => Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.applyOpacity(0.5),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _onOrderTap(context, order),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Mã đơn và trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đơn hàng #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Thông tin khách hàng (nếu có)
                if (order.user != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        order.user!.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Danh sách sản phẩm
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.applyOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Sản phẩm (${order.items.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...productNames.map(
                        (name) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasMoreProducts)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${order.items.length - 3} sản phẩm khác',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer: Tổng tiền và ngày tạo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (order.createdAt != null)
                      Text(
                        DateHelper.formatDateTime(order.createdAt!),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    Text(
                      CurrencyHelper.formatCurrency(order.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tile rút gọn: chỉ Đơn hàng #, trạng thái, ngày giờ, số tiền.
  Widget _buildOrderTileCompact(Order order, ColorScheme colorScheme) {
    return Builder(
      builder: (context) => Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.applyOpacity(0.5),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _onOrderTap(context, order),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Đơn hàng #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (order.createdAt != null)
                        Text(
                          DateHelper.formatDateTime(order.createdAt!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyHelper.formatCurrency(order.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text('Trang $currentPage/$totalPages', style: textStyle),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: currentPage > 1
                ? () => onPageChanged?.call(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: currentPage < totalPages
                ? () => onPageChanged?.call(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 64), // né floating button
        ],
      ),
    );
  }
}
