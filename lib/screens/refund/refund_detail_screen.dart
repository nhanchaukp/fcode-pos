import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/ui/components/refund_reason_badge.dart';
import 'package:fcode_pos/ui/components/refund_status_badge.dart';
import 'package:fcode_pos/ui/components/refund_type_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

class RefundDetailScreen extends StatelessWidget {
  final Refund refund;

  const RefundDetailScreen({super.key, required this.refund});

  ColorScheme colorScheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết hoàn tiền #${refund.id}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(context),

            const SizedBox(height: 8),

            // Amount breakdown
            _buildAmountCard(context),

            const SizedBox(height: 8),

            // Order information
            _buildOrderCard(context),

            const SizedBox(height: 8),

            // Order item information (if available)
            if (refund.orderItem != null) ...[
              _buildOrderItemCard(context),
              const SizedBox(height: 8),
            ],

            // Customer information
            _buildCustomerCard(context),

            const SizedBox(height: 8),

            // Processing information
            if (refund.processedBy != null || refund.processor != null) ...[
              _buildProcessingCard(context),
              const SizedBox(height: 8),
            ],

            // Notes and metadata
            _buildNotesCard(context),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yêu cầu hoàn tiền',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme(context).onSurfaceVariant,
                ),
              ),
              RefundStatusBadge(status: refund.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RefundTypeBadge(type: refund.type),
                    RefundReasonBadge(reason: refund.reason),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Ngày tạo',
            refund.createdAt != null
                ? DateHelper.formatDateTime(refund.createdAt!)
                : 'N/A',
          ),
          if (refund.processedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.schedule,
              'Ngày xử lý',
              DateHelper.formatDateTime(refund.processedAt!),
            ),
          ],
          if (refund.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.check_circle,
              'Ngày hoàn thành',
              DateHelper.formatDateTime(refund.completedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số tiền',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme(context).onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            context,
            'Số tiền hoàn',
            refund.amount.round(),
            isHighlight: false,
          ),
          const SizedBox(height: 8),
          _buildAmountRow(context, 'Phí', refund.fee.round(), isNegative: true),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.7,
            color: colorScheme(context).outlineVariant.applyOpacity(0.6),
          ),
          const SizedBox(height: 8),
          _buildAmountRow(
            context,
            'Tổng thực hoàn',
            refund.finalAmount.round(),
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context) {
    final order = refund.order;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme(context).onSurface,
                ),
              ),
              if (order != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: order.id.toString()),
                      ),
                    );
                  },
                  tooltip: 'Xem đơn hàng',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (order != null) ...[
            _buildInfoRow(
              context,
              Icons.receipt_long,
              'Mã đơn hàng',
              '#${order.id}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.attach_money,
              'Tổng đơn hàng',
              CurrencyHelper.formatCurrency(order.total),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.info_outline,
              'Trạng thái',
              order.status,
            ),
            if (order.createdAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'Ngày tạo',
                DateHelper.formatDateTime(order.createdAt!),
              ),
            ],
          ] else
            Text(
              'Không có thông tin đơn hàng',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme(context).onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context) {
    final item = refund.orderItem!;
    final product = item.product;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme(context).onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (product != null) ...[
            Text(
              product.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            context,
            Icons.shopping_cart,
            'Số lượng',
            '${item.quantity}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            Icons.attach_money,
            'Giá bán',
            CurrencyHelper.formatCurrency(item.price),
          ),
          if (item.refundedAmount > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.money_off,
              'Số tiền đã hoàn',
              CurrencyHelper.formatCurrency(item.refundedAmount),
            ),
          ],
          if (item.refundStatus != null && item.refundStatus != 'none') ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.info,
              'Trạng thái hoàn',
              item.refundStatus!,
            ),
          ],
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Ghi chú sản phẩm:',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme(context).onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.note!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final user = refund.user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Khách hàng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme(context).onSurface,
                ),
              ),
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(userId: user.id),
                      ),
                    );
                  },
                  tooltip: 'Xem khách hàng',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (user != null) ...[
            _buildInfoRow(context, Icons.person, 'Tên', user.name),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.email, 'Email', user.email),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.phone, 'Số điện thoại', user.phone!),
            ],
          ] else
            Text(
              'Không có thông tin khách hàng',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme(context).onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    final processor = refund.processor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xử lý bởi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme(context).onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (processor != null) ...[
            _buildInfoRow(context, Icons.person, 'Người xử lý', processor.name),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.email, 'Email', processor.email),
          ] else
            Text(
              'Chưa có người xử lý',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme(context).onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    final hasAnyNote =
        (refund.description != null && refund.description!.isNotEmpty) ||
        (refund.adminNotes != null && refund.adminNotes!.isNotEmpty) ||
        (refund.customerNotes != null && refund.customerNotes!.isNotEmpty) ||
        (refund.metadata != null && refund.metadata!.isNotEmpty);

    if (!hasAnyNote) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme(context).onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (refund.description != null && refund.description!.isNotEmpty) ...[
            _buildNoteSection(context, 'Mô tả', refund.description!),
          ],
          if (refund.adminNotes != null && refund.adminNotes!.isNotEmpty) ...[
            if (refund.description != null && refund.description!.isNotEmpty)
              const SizedBox(height: 12),
            _buildNoteSection(context, 'Ghi chú quản trị', refund.adminNotes!),
          ],
          if (refund.customerNotes != null &&
              refund.customerNotes!.isNotEmpty) ...[
            if ((refund.description != null &&
                    refund.description!.isNotEmpty) ||
                (refund.adminNotes != null && refund.adminNotes!.isNotEmpty))
              const SizedBox(height: 12),
            _buildNoteSection(
              context,
              'Ghi chú khách hàng',
              refund.customerNotes!,
            ),
          ],
          if (refund.metadata != null && refund.metadata!.isNotEmpty) ...[
            if ((refund.description != null &&
                    refund.description!.isNotEmpty) ||
                (refund.adminNotes != null && refund.adminNotes!.isNotEmpty) ||
                (refund.customerNotes != null &&
                    refund.customerNotes!.isNotEmpty))
              const SizedBox(height: 12),
            _buildNoteSection(context, 'Metadata', refund.metadata.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme(context).onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme(context).onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    int amount, {
    bool isHighlight = false,
    bool isNegative = false,
  }) {
    final displayAmount = isNegative ? -amount : amount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: colorScheme(context).onSurface,
          ),
        ),
        Text(
          CurrencyHelper.formatCurrency(displayAmount),
          style: TextStyle(
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight
                ? colorScheme(context).primary
                : (isNegative
                      ? colorScheme(context).error
                      : colorScheme(context).onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme(context).onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme(context).surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
