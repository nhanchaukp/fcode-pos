import 'dart:convert';

import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_add_session_screen.dart'
    show ChatGptBrowserLoginScreen, ChatGptManualJsonScreen;
import 'package:fcode_pos/screens/chatgpt/chatgpt_session_detail_screen.dart';
import 'package:fcode_pos/services/chatgpt_session_service.dart';
import 'package:fcode_pos/storage/chatgpt_session_storage.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ChatGptSessionScreen extends StatefulWidget {
  const ChatGptSessionScreen({super.key});

  @override
  State<ChatGptSessionScreen> createState() => _ChatGptSessionScreenState();
}

class _ChatGptSessionScreenState extends State<ChatGptSessionScreen> {
  final _service = ChatGptSessionService();
  final _searchController = TextEditingController();

  List<ChatGptSession> _sessions = [];
  List<ChatGptSession> _filtered = [];
  bool _isLoading = true;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await ChatGptSessionStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _filtered = _applySearch(sessions);
      _isLoading = false;
    });
  }

  void _onSearch() => setState(() => _filtered = _applySearch(_sessions));

  List<ChatGptSession> _applySearch(List<ChatGptSession> all) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return List.of(all);
    return all
        .where(
          (s) =>
              s.email.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);

  Future<void> _openBrowserLogin() async {
    setState(() => _fabOpen = false);
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChatGptBrowserLoginScreen()),
    );
    if (added == true) _loadSessions();
  }

  Future<void> _openManualJson() async {
    setState(() => _fabOpen = false);
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChatGptManualJsonScreen()),
    );
    if (added == true) _loadSessions();
  }

  Future<void> _deleteSession(ChatGptSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa session'),
        content: Text('Bạn có chắc muốn xóa session của ${session.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ChatGptSessionStorage.delete(session.email);
    _loadSessions();
  }

  void _viewJson(ChatGptSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGptSessionDetailScreen(session: session),
      ),
    );
  }

  Future<void> _copyJson(ChatGptSession session) async {
    final pretty = const JsonEncoder.withIndent('  ')
        .convert(jsonDecode(session.sessionJson));
    await Clipboard.setData(ClipboardData(text: pretty));
    if (!mounted) return;
    Toastr.success('Đã copy session JSON', context: context);
  }

  Future<void> _fetchInfo(ChatGptSession session) async {
    final token = session.accessToken;
    if (token == null || token.isEmpty) {
      Toastr.warning('Không tìm thấy access token', context: context);
      return;
    }

    // Hiển thị dialog loading trước
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FetchInfoDialog(isLoading: true),
    );

    Map<String, dynamic>? info;
    String? errorMsg;
    try {
      info = await _service.fetchUserInfo(token);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // đóng loading dialog

    showDialog(
      context: context,
      builder: (_) => _FetchInfoDialog(
        isLoading: false,
        info: info,
        errorMsg: errorMsg,
      ),
    );
  }

  void _showActions(ChatGptSession session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _SessionActionsSheet(
        session: session,
        onViewJson: () {
          Navigator.pop(ctx);
          _viewJson(session);
        },
        onCopyJson: () {
          Navigator.pop(ctx);
          _copyJson(session);
        },
        onFetchInfo: () {
          Navigator.pop(ctx);
          _fetchInfo(session);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteSession(session);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatGPT Sessions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo email hoặc tên...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _searchController.clear,
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? _EmptyState(
              hasSearch: _searchController.text.isNotEmpty,
              onBrowserLogin: _openBrowserLogin,
              onManualJson: _openManualJson,
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final session = _filtered[index];
                  return _SessionCard(
                    session: session,
                    onTap: () => _showActions(session),
                    onDismiss: () => _deleteSession(session),
                  );
                },
              ),
            ),
      floatingActionButton: _SpeedDial(
        isOpen: _fabOpen,
        onToggle: _toggleFab,
        items: [
          _SpeedDialItem(
            icon: Icons.code,
            label: 'Nhập JSON',
            onTap: _openManualJson,
          ),
          _SpeedDialItem(
            icon: Icons.language,
            label: 'Đăng nhập',
            onTap: _openBrowserLogin,
          ),
        ],
      ),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDismiss,
  });

  final ChatGptSession session;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(session.email),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDismiss();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Avatar(session: session, colorScheme: colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name.isNotEmpty ? session.name : session.email,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (session.name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          session.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            session.isExpired
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            size: 12,
                            color: session.isExpired
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.isExpired ? 'Đã hết hạn' : 'Còn hiệu lực',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: session.isExpired
                                      ? Colors.red
                                      : Colors.green,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            'Lưu ${_formatDate(session.savedAt)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yy HH:mm').format(dt);
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.session, required this.colorScheme});

  final ChatGptSession session;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: session.image != null
          ? NetworkImage(session.image!)
          : null,
      child: session.image == null
          ? Text(
              session.name.isNotEmpty
                  ? session.name[0].toUpperCase()
                  : session.email.isNotEmpty
                  ? session.email[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

// ── Actions Bottom Sheet ──────────────────────────────────────────────────────

class _SessionActionsSheet extends StatelessWidget {
  const _SessionActionsSheet({
    required this.session,
    required this.onViewJson,
    required this.onCopyJson,
    required this.onFetchInfo,
    required this.onDelete,
  });

  final ChatGptSession session;
  final VoidCallback onViewJson;
  final VoidCallback onCopyJson;
  final VoidCallback onFetchInfo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  _Avatar(session: session, colorScheme: colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name.isNotEmpty ? session.name : session.email,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (session.name.isNotEmpty)
                          Text(
                            session.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Fetch Info'),
              subtitle: const Text('Kiểm tra token & lấy thông tin tài khoản'),
              onTap: onFetchInfo,
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Xem Session JSON'),
              onTap: onViewJson,
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy JSON'),
              subtitle: const Text('Copy toàn bộ session JSON'),
              onTap: onCopyJson,
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa session',
                  style: TextStyle(color: Colors.red)),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fetch Info Dialog ─────────────────────────────────────────────────────────

class _FetchInfoDialog extends StatelessWidget {
  const _FetchInfoDialog({
    required this.isLoading,
    this.info,
    this.errorMsg,
  });

  final bool isLoading;
  final Map<String, dynamic>? info;
  final String? errorMsg;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Đang kiểm tra token...')),
            ],
          ),
        ),
      );
    }

    if (errorMsg != null) {
      return AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 36),
        title: const Text('Token không hợp lệ'),
        content: Text(
          errorMsg!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      );
    }

    // Success — hiển thị user info
    final orgs = (info?['orgs']?['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final orgName = orgs.isNotEmpty
        ? (orgs.first['title'] as String? ?? orgs.first['name'] as String?)
        : null;

    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
      title: const Text('Token hợp lệ'),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoRow2('Tên', info?['name'] as String?),
          _InfoRow2('Email', info?['email'] as String?),
          _InfoRow2('User ID', info?['id'] as String?),
          _InfoRow2('Tổ chức', orgName),
          _InfoRow2(
            'MFA',
            info?['mfa_flag_enabled'] == true ? 'Bật' : 'Tắt',
          ),
          if (info?['phone_number'] != null)
            _InfoRow2('SĐT', info!['phone_number'] as String?),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Token còn hiệu lực',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        TextButton(
          onPressed: () {
            final jsonStr = const JsonEncoder.withIndent('  ').convert(info);
            Clipboard.setData(ClipboardData(text: jsonStr));
            Navigator.pop(context);
            Toastr.success('Đã copy thông tin tài khoản',
                context: context);
          },
          child: const Text('Copy JSON'),
        ),
      ],
    );
  }
}

class _InfoRow2 extends StatelessWidget {
  const _InfoRow2(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Speed Dial FAB ────────────────────────────────────────────────────────────

class _SpeedDialItem {
  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({
    required this.isOpen,
    required this.onToggle,
    required this.items,
  });

  final bool isOpen;
  final VoidCallback onToggle;
  final List<_SpeedDialItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini items (top → bottom order = items list order)
        for (final item in items) ...[
          AnimatedSlide(
            offset: isOpen ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: IgnorePointer(
                ignoring: !isOpen,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.label,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Mini FAB
                      FloatingActionButton.small(
                        heroTag: item.label,
                        onPressed: item.onTap,
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        elevation: 2,
                        child: Icon(item.icon, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: onToggle,
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasSearch,
    required this.onBrowserLogin,
    required this.onManualJson,
  });

  final bool hasSearch;
  final VoidCallback onBrowserLogin;
  final VoidCallback onManualJson;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.person_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Không tìm thấy kết quả' : 'Chưa có session nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Thêm tài khoản ChatGPT bằng cách đăng nhập hoặc nhập JSON',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onBrowserLogin,
                    icon: const Icon(Icons.language, size: 18),
                    label: const Text('Đăng nhập'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onManualJson,
                    icon: const Icon(Icons.code, size: 18),
                    label: const Text('Nhập JSON'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
