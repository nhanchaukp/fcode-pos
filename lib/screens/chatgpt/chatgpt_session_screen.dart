import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_add_session_screen.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_browser_screen.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_session_detail_screen.dart';
import 'package:fcode_pos/services/chatgpt_session_service.dart';
import 'package:fcode_pos/storage/chatgpt_session_storage.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
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
  final Set<String> _refreshing = {};

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

  void _onSearch() {
    setState(() => _filtered = _applySearch(_sessions));
  }

  List<ChatGptSession> _applySearch(List<ChatGptSession> all) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return List.of(all);
    return all
        .where((s) =>
            s.email.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _addSession() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChatGptAddSessionScreen()),
    );
    if (added == true) _loadSessions();
  }

  Future<void> _deleteSession(ChatGptSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa session'),
        content:
            Text('Bạn có chắc muốn xóa session của ${session.email} không?'),
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

  Future<void> _refreshSession(ChatGptSession session) async {
    setState(() => _refreshing.add(session.email));
    try {
      final updated = await _service.refreshSession(session);
      await ChatGptSessionStorage.save(updated);
      _loadSessions();
      if (!mounted) return;
      Toastr.success('Đã làm mới thông tin session', context: context);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi làm mới: $e', context: context);
    } finally {
      if (mounted) setState(() => _refreshing.remove(session.email));
    }
  }

  Future<void> _openBrowser(ChatGptSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGptBrowserScreen(session: session),
      ),
    );
  }

  Future<void> _viewSessionJson(ChatGptSession session) async {
    // Fetch latest session JSON ngầm trước khi hiển thị
    ChatGptSession display = session;
    try {
      display = await _service.refreshSession(session);
      await ChatGptSessionStorage.save(display);
      _loadSessions();
    } catch (_) {
      // Dùng cached session nếu fetch thất bại
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGptSessionDetailScreen(session: display),
      ),
    );
  }

  void _showActions(ChatGptSession session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _SessionActionsSheet(
        session: session,
        isRefreshing: _refreshing.contains(session.email),
        onOpenBrowser: () {
          Navigator.pop(ctx);
          _openBrowser(session);
        },
        onViewJson: () {
          Navigator.pop(ctx);
          _viewSessionJson(session);
        },
        onRefresh: () {
          Navigator.pop(ctx);
          _refreshSession(session);
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
                        onPressed: () {
                          _searchController.clear();
                        },
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
                  onAdd: _addSession,
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
                        isRefreshing: _refreshing.contains(session.email),
                        onTap: () => _showActions(session),
                        onDismiss: () => _deleteSession(session),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        tooltip: 'Thêm tài khoản',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isRefreshing,
    required this.onTap,
    required this.onDismiss,
  });

  final ChatGptSession session;
  final bool isRefreshing;
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
          borderRadius: BorderRadius.circular(12),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _PlanChip(session: session),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                            session.isExpired
                                ? 'Đã hết hạn'
                                : 'Còn hiệu lực',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: session.isExpired
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            'Lưu ${_formatDate(session.savedAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isRefreshing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yy HH:mm').format(dt);
  }
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
      backgroundImage:
          session.image != null ? NetworkImage(session.image!) : null,
      child: session.image == null
          ? Text(
              session.name.isNotEmpty ? session.name[0].toUpperCase() : '?',
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

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.session});

  final ChatGptSession session;

  @override
  Widget build(BuildContext context) {
    final isPro = session.isPro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPro
            ? Colors.amber.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPro ? Colors.amber : Colors.grey,
          width: 0.8,
        ),
      ),
      child: Text(
        session.planType?.toUpperCase() ?? 'FREE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isPro ? Colors.amber.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ── Actions Bottom Sheet ──────────────────────────────────────────────────────

class _SessionActionsSheet extends StatelessWidget {
  const _SessionActionsSheet({
    required this.session,
    required this.isRefreshing,
    required this.onOpenBrowser,
    required this.onViewJson,
    required this.onRefresh,
    required this.onDelete,
  });

  final ChatGptSession session;
  final bool isRefreshing;
  final VoidCallback onOpenBrowser;
  final VoidCallback onViewJson;
  final VoidCallback onRefresh;
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
                          session.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
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
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Mở ChatGPT'),
              subtitle: const Text('Mở với cookie đã lưu'),
              onTap: onOpenBrowser,
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Xem Session JSON'),
              subtitle: const Text('Fetch & hiển thị dữ liệu session'),
              onTap: onViewJson,
            ),
            ListTile(
              leading: isRefreshing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              title: const Text('Làm mới thông tin'),
              subtitle: const Text('Fetch ngầm và cập nhật dữ liệu'),
              enabled: !isRefreshing,
              onTap: isRefreshing ? null : onRefresh,
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onAdd});

  final bool hasSearch;
  final VoidCallback onAdd;

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
              hasSearch
                  ? 'Không tìm thấy kết quả'
                  : 'Chưa có session nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Tap nút + để thêm tài khoản ChatGPT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Thêm tài khoản'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
