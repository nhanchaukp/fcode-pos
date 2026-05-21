import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_customer_detail_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotCustomersScreen extends StatefulWidget {
  const TelegramBotCustomersScreen({super.key, required this.token});

  final String token;

  @override
  State<TelegramBotCustomersScreen> createState() =>
      _TelegramBotCustomersScreenState();
}

class _TelegramBotCustomersScreenState
    extends State<TelegramBotCustomersScreen> {
  final _searchController = TextEditingController();

  late final TelegramBotApiClient _api;
  bool _isLoading = true;
  String? _error;
  List<JsonMap> _users = const [];

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getUsers();
      if (!mounted) {
        return;
      }
      setState(() => _users = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải danh sách khách hàng';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<JsonMap> get _filteredUsers {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _users;
    }

    return _users
        .where((row) {
          final values = [
            row['id'],
            row['telegram_id'],
            row['username'],
            row['full_name'],
          ].map((item) => item?.toString().toLowerCase() ?? '');

          return values.any((text) => text.contains(keyword));
        })
        .toList(growable: false);
  }

  Future<void> _openCustomerDetail(int userId) async {
    if (userId <= 0) {
      Toastr.error('Không tìm thấy user_id hợp lệ');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelegramBotCustomerDetailScreen(
          token: widget.token,
          userId: userId,
        ),
      ),
    );

    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredUsers;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot • Khách hàng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo Telegram ID / username',
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
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(rows)),
        ],
      ),
    );
  }

  Widget _buildBody(List<JsonMap> rows) {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _users.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _loadUsers);
    }

    if (rows.isEmpty) {
      return const Center(child: Text('Không có khách hàng phù hợp'));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        itemBuilder: (context, index) {
          final row = rows[index];
          final userId = _toInt(row['id']);
          final telegramId = (row['telegram_id'] ?? '-').toString();
          final username = (row['username'] ?? '').toString();
          final fullName = (row['full_name'] ?? '').toString();
          final balance = (row['balance'] as num?)?.toInt() ?? 0;
          final isActive = (row['is_active'] as num?)?.toInt() == 1;

          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: InkWell(
              onTap: () => _openCustomerDetail(userId),
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
                            username.isEmpty
                                ? 'Telegram $telegramId'
                                : '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(isActive ? 'ACTIVE' : 'INACTIVE'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (fullName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.tag_rounded,
                          label: '#$userId • TG: $telegramId',
                        ),
                        _MetaChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: CurrencyHelper.formatCurrency(balance),
                        ),
                      ],
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
          Text(label, style: Theme.of(context).textTheme.labelSmall),
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
