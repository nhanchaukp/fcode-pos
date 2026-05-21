import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotReportsScreen extends StatefulWidget {
  const TelegramBotReportsScreen({super.key, required this.token});

  final String token;

  @override
  State<TelegramBotReportsScreen> createState() =>
      _TelegramBotReportsScreenState();
}

class _TelegramBotReportsScreenState extends State<TelegramBotReportsScreen> {
  late final TelegramBotApiClient _api;

  bool _isLoading = true;
  String? _error;
  JsonMap _overview = const {};
  List<JsonMap> _trend = const [];

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getDashboardOverview(),
        _api.getRevenueTrend(days: 14),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = results[0] as JsonMap;
        _trend = results[1] as List<JsonMap>;
      });
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải báo cáo Telegram Bot';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot • Báo cáo'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading && _overview.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _overview.isEmpty
          ? _ErrorView(message: _error!, onRetry: _loadData)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildOverviewGrid(context),
                  const SizedBox(height: 12),
                  _buildOrderStatusCard(),
                  const SizedBox(height: 12),
                  _buildRevenueTrendCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totals = _toMap(_overview['totals']);
    final revenue = _toMap(_overview['revenue']);

    final cards = [
      _MetricData('Users', '${totals['users'] ?? 0}', Icons.people_alt_rounded),
      _MetricData(
        'Products',
        '${totals['products'] ?? 0}',
        Icons.inventory_2_rounded,
      ),
      _MetricData(
        'Orders',
        '${totals['orders'] ?? 0}',
        Icons.receipt_long_rounded,
      ),
      _MetricData(
        'Revenue Today',
        CurrencyHelper.formatCurrency(_toInt(revenue['today'])),
        Icons.paid_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          elevation: 0,
          color: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(card.icon, size: 18, color: cs.primary),
                const SizedBox(height: 6),
                Text(card.title, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  card.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusCard() {
    final cs = Theme.of(context).colorScheme;
    final statuses = _toMap(_overview['ordersByStatus']);

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
              'Trạng thái đơn hàng',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('PENDING: ${statuses['pendingPayment'] ?? 0}'),
                ),
                Chip(label: Text('PAID: ${statuses['paid'] ?? 0}')),
                Chip(label: Text('DELIVERED: ${statuses['delivered'] ?? 0}')),
                Chip(label: Text('EXPIRED: ${statuses['expired'] ?? 0}')),
                Chip(label: Text('CANCELLED: ${statuses['cancelled'] ?? 0}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTrendCard() {
    final cs = Theme.of(context).colorScheme;

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
              'Revenue trend (14 ngày)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_trend.isEmpty)
              const Text('Chưa có dữ liệu')
            else
              ..._trend.take(14).map((item) {
                final date = (item['date'] ?? '-').toString();
                final revenue = CurrencyHelper.formatCurrency(
                  _toInt(item['revenue']),
                );
                final paidOrders = item['paidOrders'] ?? 0;
                final pendingOrders = item['pendingOrders'] ?? 0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.show_chart_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                  title: Text(date),
                  subtitle: Text('Paid: $paidOrders • Pending: $pendingOrders'),
                  trailing: Text(revenue),
                );
              }),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  JsonMap _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
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
