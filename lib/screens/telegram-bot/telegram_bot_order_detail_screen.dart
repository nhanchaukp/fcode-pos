import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_customer_detail_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_product_detail_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotOrderDetailScreen extends StatefulWidget {
  const TelegramBotOrderDetailScreen({
    super.key,
    required this.token,
    required this.orderId,
  });

  final String token;
  final int orderId;

  @override
  State<TelegramBotOrderDetailScreen> createState() =>
      _TelegramBotOrderDetailScreenState();
}

class _TelegramBotOrderDetailScreenState
    extends State<TelegramBotOrderDetailScreen> {
  late final TelegramBotApiClient _api;

  bool _isLoading = true;
  String? _error;
  JsonMap _data = const {};

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getOrderDetail(widget.orderId);
      if (!mounted) {
        return;
      }
      setState(() => _data = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải chi tiết đơn hàng';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCustomer(int userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelegramBotCustomerDetailScreen(
          token: widget.token,
          userId: userId,
        ),
      ),
    );
  }

  Future<void> _openProduct(int productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelegramBotProductDetailScreen(
          token: widget.token,
          productId: productId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _data;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng #${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading && order.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && order.isEmpty
          ? _ErrorView(message: _error!, onRetry: _loadDetail)
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildOrderCard(order),
                  const SizedBox(height: 12),
                  _buildDeliveryLogs(),
                  const SizedBox(height: 12),
                  _buildInventoryItems(),
                  const SizedBox(height: 12),
                  _buildMessageLogs(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderCard(JsonMap order) {
    final cs = Theme.of(context).colorScheme;
    final total = _toInt(order['total_amount']);
    final userId = _toInt(order['user_id']);
    final productId = _toInt(order['product_id']);

    final userTitle = (order['username'] ?? order['telegram_id'] ?? '-')
        .toString();
    final productTitle = (order['product_name'] ?? '-').toString();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order['order_code'] ?? '#${order['id'] ?? '-'}'}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Status: ${order['status'] ?? '-'}')),
                Chip(label: Text('Type: ${order['order_type'] ?? '-'}')),
                Chip(label: Text('Qty: ${order['qty'] ?? 0}')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tổng tiền: ${CurrencyHelper.formatCurrency(total)}'),
            Text('User: $userTitle'),
            Text('Sản phẩm: $productTitle'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (userId > 0)
                  OutlinedButton.icon(
                    onPressed: () => _openCustomer(userId),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('Mở khách hàng'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                  ),
                if (productId > 0)
                  OutlinedButton.icon(
                    onPressed: () => _openProduct(productId),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Mở sản phẩm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryLogs() {
    final cs = Theme.of(context).colorScheme;
    final rows = _toList(_data['delivery_logs']);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery logs',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('Chưa có delivery log')
            else
              ...rows.map((row) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_rounded, size: 18),
                  title: Text((row['delivered_by'] ?? '-').toString()),
                  subtitle: Text((row['delivery_content'] ?? '').toString()),
                  trailing: Text((row['created_at'] ?? '').toString()),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItems() {
    final cs = Theme.of(context).colorScheme;
    final rows = _toList(_data['inventory_items']);
    final productId = _toInt(_data['product_id']);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory items',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('Không có inventory item cho đơn này')
            else
              ...rows.take(80).map((row) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text((row['content'] ?? '').toString()),
                  subtitle: Text('Status: ${row['status'] ?? '-'}'),
                  trailing: productId > 0
                      ? IconButton(
                          tooltip: 'Mở sản phẩm',
                          color: cs.primary,
                          onPressed: () => _openProduct(productId),
                          icon: const Icon(Icons.open_in_new_rounded),
                        )
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageLogs() {
    final cs = Theme.of(context).colorScheme;
    final rows = _toList(_data['message_logs']);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Telegram message logs',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('Chưa có message log')
            else
              ...rows.take(80).map((row) {
                final messageType = (row['message_type'] ?? '-').toString();
                final deleted = _toInt(row['is_deleted']) == 1;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(messageType),
                  subtitle: Text(
                    'chat_id=${row['chat_id'] ?? '-'} • message_id=${row['message_id'] ?? '-'}',
                  ),
                  trailing: Chip(
                    label: Text(deleted ? 'DELETED' : 'ACTIVE'),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<JsonMap> _toList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Object>()
        .map(
          (item) => item is Map<String, dynamic>
              ? item
              : item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{},
        )
        .toList(growable: false);
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
