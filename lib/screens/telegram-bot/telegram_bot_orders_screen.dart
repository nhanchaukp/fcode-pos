import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_order_detail_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotOrdersScreen extends StatefulWidget {
  const TelegramBotOrdersScreen({
    super.key,
    required this.token,
    this.initialStatus,
    this.initialSearch,
  });

  final String token;
  final String? initialStatus;
  final String? initialSearch;

  @override
  State<TelegramBotOrdersScreen> createState() =>
      _TelegramBotOrdersScreenState();
}

class _TelegramBotOrdersScreenState extends State<TelegramBotOrdersScreen> {
  static const _statusOptions = <String>[
    '',
    'PENDING_PAYMENT',
    'PAID',
    'DELIVERED',
    'EXPIRED',
    'CANCELLED',
  ];

  late final TelegramBotApiClient _api;
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = '';
  List<JsonMap> _orders = const [];

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);

    if (_statusOptions.contains(widget.initialStatus)) {
      _selectedStatus = widget.initialStatus ?? '';
    }

    if ((widget.initialSearch ?? '').trim().isNotEmpty) {
      _searchController.text = widget.initialSearch!.trim();
    }

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getOrders(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() => _orders = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải danh sách đơn hàng';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<JsonMap> get _filteredOrders {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _orders;
    }

    return _orders
        .where((row) {
          final values = [
            row['id'],
            row['order_code'],
            row['status'],
            row['order_type'],
            row['product_id'],
            row['product_name'],
            row['user_id'],
            row['telegram_id'],
            row['username'],
          ].map((item) => item?.toString().toLowerCase() ?? '');

          return values.any((value) => value.contains(keyword));
        })
        .toList(growable: false);
  }

  Future<void> _openOrderDetail(int orderId) async {
    if (orderId <= 0) {
      Toastr.error('order_id không hợp lệ');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelegramBotOrderDetailScreen(token: widget.token, orderId: orderId),
      ),
    );

    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredOrders;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot • Đơn hàng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã đơn / user / sản phẩm',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: cs.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    items: _statusOptions
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status.isEmpty ? 'Tất cả trạng thái' : status,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    decoration: InputDecoration(
                      labelText: 'Lọc trạng thái',
                      prefixIcon: const Icon(Icons.filter_alt_rounded),
                      filled: true,
                      fillColor: cs.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      _selectedStatus = value ?? '';
                      _loadOrders();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(rows)),
        ],
      ),
    );
  }

  Widget _buildBody(List<JsonMap> rows) {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _loadOrders);
    }

    if (rows.isEmpty) {
      return const Center(child: Text('Không có đơn hàng phù hợp'));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        itemBuilder: (context, index) {
          final row = rows[index];
          final orderId = _toInt(row['id']);
          final total = (row['total_amount'] as num?)?.toInt() ?? 0;
          final status = (row['status'] ?? '-').toString();
          final productName = (row['product_name'] ?? 'N/A').toString();
          final userName = (row['username'] ?? row['telegram_id'] ?? 'N/A')
              .toString();
          final code = (row['order_code'] ?? '#${row['id'] ?? '-'}').toString();

          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: InkWell(
              onTap: () => _openOrderDetail(orderId),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(status),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.inventory_2_outlined,
                          label: productName,
                        ),
                        _MetaChip(
                          icon: Icons.person_outline_rounded,
                          label: userName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyHelper.formatCurrency(total),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: rows.length,
      ),
    );
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
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
