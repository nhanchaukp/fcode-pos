import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_bot_info_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_customers_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_login_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_orders_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_products_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_reports_screen.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotHubScreen extends StatefulWidget {
  const TelegramBotHubScreen({super.key});

  @override
  State<TelegramBotHubScreen> createState() => _TelegramBotHubScreenState();
}

class _TelegramBotHubScreenState extends State<TelegramBotHubScreen> {
  final _sessionStorage = TelegramBotSessionStorage();

  bool _isLoading = true;
  TelegramBotSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);

    final session = await _sessionStorage.read();
    if (!mounted) {
      return;
    }

    if (session == null) {
      setState(() {
        _session = null;
        _isLoading = false;
      });
      return;
    }

    final api = TelegramBotApiClient(token: session.token);
    try {
      final me = await api.getMe();
      final username = (me['username'] ?? session.username).toString();
      _session = TelegramBotSession(token: session.token, username: username);
      await _sessionStorage.save(_session!);
    } catch (_) {
      await _sessionStorage.clear();
      _session = null;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _openLogin() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelegramBotLoginScreen()),
    );

    if (success == true) {
      await _loadSession();
    }
  }

  Future<void> _logout() async {
    await _sessionStorage.clear();
    if (!mounted) {
      return;
    }

    setState(() => _session = null);
    Toastr.success('Đã đăng xuất Telegram Bot');
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadSession,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: session == null ? 'Đăng nhập' : 'Đăng xuất',
            onPressed: session == null ? _openLogin : _logout,
            icon: Icon(
              session == null ? Icons.login_rounded : Icons.logout_rounded,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : session == null
          ? _LoginRequiredView(onLogin: _openLogin)
          : _TelegramBotMenuView(session: session),
    );
  }
}

class _LoginRequiredView extends StatelessWidget {
  const _LoginRequiredView({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 26,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bạn cần đăng nhập để quản lý Telegram Bot',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Base API: ${Environment.telegramBotBaseApi}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Đăng nhập Telegram Bot'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TelegramBotMenuView extends StatelessWidget {
  const _TelegramBotMenuView({required this.session});

  final TelegramBotSession session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = [
      _FeatureItem(
        title: 'Quản lý sản phẩm',
        subtitle: 'Thêm/sửa sản phẩm, tồn kho, mapping provider',
        icon: Icons.inventory_2_rounded,
        builder: (_) => TelegramBotProductsScreen(token: session.token),
      ),
      _FeatureItem(
        title: 'Đơn hàng',
        subtitle: 'Theo dõi trạng thái đơn và xem chi tiết',
        icon: Icons.receipt_long_rounded,
        builder: (_) => TelegramBotOrdersScreen(token: session.token),
      ),
      _FeatureItem(
        title: 'Khách hàng',
        subtitle: 'Danh sách user Telegram và lịch sử mua hàng',
        icon: Icons.people_alt_rounded,
        builder: (_) => TelegramBotCustomersScreen(token: session.token),
      ),
      _FeatureItem(
        title: 'Báo cáo',
        subtitle: 'Tổng quan doanh thu và xu hướng',
        icon: Icons.query_stats_rounded,
        builder: (_) => TelegramBotReportsScreen(token: session.token),
      ),
      _FeatureItem(
        title: 'Bot info',
        subtitle: 'Trạng thái webhook / commands / token',
        icon: Icons.smart_toy_rounded,
        builder: (_) => TelegramBotInfoScreen(token: session.token),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SessionHeader(session: session);
        }

        final item = items[index - 1];
        return Card(
          elevation: 0,
          color: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(item.icon, color: cs.primary),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(item.subtitle),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.primary),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: item.builder));
            },
          ),
        );
      },
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemCount: items.length + 1,
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final TelegramBotSession session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary,
            child: Text(
              session.username.isEmpty
                  ? 'A'
                  : session.username[0].toUpperCase(),
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${session.username}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã đăng nhập Telegram Bot Admin',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                Text(
                  Environment.telegramBotBaseApi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
