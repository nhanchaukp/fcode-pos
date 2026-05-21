import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_order_detail_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_product_detail_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotCustomerDetailScreen extends StatefulWidget {
  const TelegramBotCustomerDetailScreen({
    super.key,
    required this.token,
    required this.userId,
  });

  final String token;
  final int userId;

  @override
  State<TelegramBotCustomerDetailScreen> createState() =>
      _TelegramBotCustomerDetailScreenState();
}

class _TelegramBotCustomerDetailScreenState
    extends State<TelegramBotCustomerDetailScreen> {
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
      final data = await _api.getUserDetail(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() => _data = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải chi tiết khách hàng';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openOrder(int orderId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelegramBotOrderDetailScreen(token: widget.token, orderId: orderId),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Khách hàng #${widget.userId}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data.isEmpty
          ? _ErrorView(message: _error!, onRetry: _loadDetail)
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildOrdersCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard() {
    final cs = Theme.of(context).colorScheme;
    final user = _toMap(_data['user']);
    final balance = _toInt(user['balance']);
    final username = (user['username'] ?? '').toString();

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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    username.isEmpty
                        ? 'Telegram ${user['telegram_id'] ?? '-'}'
                        : '@$username',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('ID: ${user['id'] ?? '-'}'),
            Text('Telegram ID: ${user['telegram_id'] ?? '-'}'),
            if ((user['full_name'] ?? '').toString().isNotEmpty)
              Text('Họ tên: ${user['full_name']}'),
            Text('Balance: ${CurrencyHelper.formatCurrency(balance)}'),
            Text('Active: ${_toInt(user['is_active']) == 1 ? 'YES' : 'NO'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final cs = Theme.of(context).colorScheme;
    final summary = _toMap(_data['summary']);

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
              'Thống kê',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Tổng đơn: ${summary['total_orders'] ?? 0}')),
                Chip(label: Text('Pending: ${summary['pending_orders'] ?? 0}')),
                Chip(label: Text('Paid: ${summary['paid_orders'] ?? 0}')),
                Chip(
                  label: Text('Delivered: ${summary['delivered_orders'] ?? 0}'),
                ),
                Chip(label: Text('Expired: ${summary['expired_orders'] ?? 0}')),
                Chip(
                  label: Text('Cancelled: ${summary['cancelled_orders'] ?? 0}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng chi: ${CurrencyHelper.formatCurrency(_toInt(summary['total_spent']))}',
            ),
            Text(
              'Tổng nạp: ${CurrencyHelper.formatCurrency(_toInt(summary['total_topped_up']))}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    final cs = Theme.of(context).colorScheme;
    final orders = _toList(_data['orders']);

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
              'Đơn hàng của khách',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const Text('Khách hàng chưa có đơn hàng')
            else
              ...orders.take(120).map((order) {
                final orderId = _toInt(order['id']);
                final productId = _toInt(order['product_id']);
                final total = _toInt(order['total_amount']);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text((order['order_code'] ?? '#$orderId').toString()),
                  subtitle: Text(
                    '${order['status'] ?? '-'} • ${(order['product_name'] ?? '-').toString()} • ${CurrencyHelper.formatCurrency(total)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Mở chi tiết đơn',
                        color: cs.primary,
                        onPressed: () => _openOrder(orderId),
                        icon: const Icon(Icons.open_in_new_rounded),
                      ),
                      if (productId > 0)
                        IconButton(
                          tooltip: 'Mở sản phẩm',
                          color: cs.primary,
                          onPressed: () => _openProduct(productId),
                          icon: const Icon(Icons.inventory_2_rounded),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  JsonMap _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
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
