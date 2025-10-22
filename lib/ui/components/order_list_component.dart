import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/order_detail_screen.dart';
import 'package:fcode_pos/ui/components/order_status_badge.dart';

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

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderTile(order, colorScheme);
            },
          ),
        ),
        _buildPaginationControls(context, colorScheme),
      ],
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

    return Builder(
      builder: (context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: () => _onOrderTap(context, order),
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
                            Icons.shopping_cart_outlined,
                            size: 14,
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
                            size: 14,
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
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant.applyOpacity(
                              0.9,
                            ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: currentPage < totalPages
                ? () => onPageChanged?.call(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}
