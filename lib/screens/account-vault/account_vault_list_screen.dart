import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/account-vault/account_vault_detail_screen.dart';
import 'package:fcode_pos/screens/account-vault/account_vault_upsert_screen.dart';
import 'package:fcode_pos/services/account_vault_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:amazing_icons/bulk.dart';
import 'package:fcode_pos/ui/components/badge/status_badges.dart';
import 'package:flutter/material.dart';

class AccountVaultListScreen extends StatefulWidget {
  const AccountVaultListScreen({super.key});

  @override
  State<AccountVaultListScreen> createState() => _AccountVaultListScreenState();
}

class _AccountVaultListScreenState extends State<AccountVaultListScreen> {
  final _service = AccountVaultService();
  final _searchController = TextEditingController();

  PaginatedData<AccountVaultItem>? _page;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;

  // Filters
  String? _filterProvider;
  bool? _filterIsActive;
  List<String> _providers = [];

  static const _perPage = 15;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final res = await _service.providers();
      if (mounted && res.data != null) {
        setState(() => _providers = res.data!);
      }
    } catch (_) {}
  }

  Future<void> _load({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final res = await _service.list(
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        provider: _filterProvider,
        isActive: _filterIsActive,
        page: page,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() => _page = res.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _page = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu.';
        _page = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountVaultUpsertScreen(providers: _providers),
      ),
    );
    if (result == true) _load(page: 1);
  }

  void _openDetail(AccountVaultItem item) async {
    var changed = false;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountVaultDetailScreen(
          item: item,
          onChanged: () => changed = true,
        ),
      ),
    );
    // Chỉ reload khi có thay đổi (sửa/xóa) ở trang chi tiết.
    if (changed && mounted) _load(page: _currentPage);
  }

  void _showFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        providers: _providers,
        selectedProvider: _filterProvider,
        selectedIsActive: _filterIsActive,
        onApply: (provider, isActive) {
          setState(() {
            _filterProvider = provider;
            _filterIsActive = isActive;
          });
          _load(page: 1);
        },
        onReset: () {
          setState(() {
            _filterProvider = null;
            _filterIsActive = null;
          });
          _load(page: 1);
        },
      ),
    );
  }

  bool get _hasFilter => _filterProvider != null || _filterIsActive != null;

  @override
  Widget build(BuildContext context) {
    final items = _page?.items ?? [];
    final pagination = _page?.pagination;

    return AppScaffold(
      title: 'Ví tài khoản',
      enableSearch: true,
      searchHint: 'Tìm email...',
      searchController: _searchController,
      onSearchChanged: (_) => _load(page: 1),
      onSearchSubmitted: (_) => _load(page: 1),
      actions: [
        IconButton(
          tooltip: 'Thêm vault',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: _navigateToCreate,
        ),
        IconButton(
          tooltip: 'Lọc',
          visualDensity: VisualDensity.compact,
          icon: Badge(
            isLabelVisible: _hasFilter,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterSheet,
        ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_hasFilter)
            _ActiveFilterBar(
              provider: _filterProvider,
              isActive: _filterIsActive,
              onClear: () {
                setState(() {
                  _filterProvider = null;
                  _filterIsActive = null;
                });
                _load(page: 1);
              },
            ),
          Expanded(child: _buildContent(items, scrollController)),
          _buildPagination(pagination),
        ],
      ),
    );
  }

  Widget _buildContent(List<AccountVaultItem> items, ScrollController scrollController) {
    if (_loading && _page == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _load(), child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không tìm thấy vault nào'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _currentPage),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) => _VaultTile(
          item: items[i],
          onTap: () => _openDetail(items[i]),
        ),
      ),
    );
  }

  Widget _buildPagination(Pagination? pagination) {
    if (pagination == null || pagination.lastPage <= 1) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.outlined(
            onPressed: !_loading && pagination.currentPage > 1
                ? () => _load(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            'Trang ${pagination.currentPage} / ${pagination.lastPage}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          IconButton.outlined(
            onPressed:
                !_loading && pagination.currentPage < pagination.lastPage
                    ? () => _load(page: pagination.currentPage + 1)
                    : null,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.providers,
    required this.selectedProvider,
    required this.selectedIsActive,
    required this.onApply,
    required this.onReset,
  });

  final List<String> providers;
  final String? selectedProvider;
  final bool? selectedIsActive;
  final void Function(String? provider, bool? isActive) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _provider;
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    _provider = widget.selectedProvider;
    _isActive = widget.selectedIsActive;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Bộ lọc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReset();
                  },
                  child: const Text('Đặt lại'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Provider
            if (widget.providers.isNotEmpty) ...[
              const Text(
                'Provider',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _provider == null,
                    onSelected: (_) => setState(() => _provider = null),
                  ),
                  ...widget.providers.map(
                    (p) => FilterChip(
                      label: Text(p),
                      selected: _provider == p,
                      onSelected: (_) => setState(() => _provider = p),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Active status
            const Text(
              'Trạng thái',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _isActive == null,
                  onSelected: (_) => setState(() => _isActive = null),
                ),
                FilterChip(
                  label: const Text('Đang dùng'),
                  selected: _isActive == true,
                  onSelected: (_) => setState(() => _isActive = true),
                ),
                FilterChip(
                  label: const Text('Vô hiệu'),
                  selected: _isActive == false,
                  onSelected: (_) => setState(() => _isActive = false),
                ),
              ],
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_provider, _isActive);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Filter Bar ─────────────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.provider,
    required this.isActive,
    required this.onClear,
  });

  final String? provider;
  final bool? isActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (provider != null) chips.add('Provider: $provider');
    if (isActive != null) chips.add(isActive! ? 'Đang dùng' : 'Vô hiệu');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              children: chips
                  .map(
                    (c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: 'Xóa bộ lọc',
          ),
        ],
      ),
    );
  }
}

// ── Vault Card ────────────────────────────────────────────────────────────────

class _VaultTile extends StatelessWidget {
  const _VaultTile({
    required this.item,
    required this.onTap,
  });

  final AccountVaultItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActiveStatusBadge(isActive: item.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          (item.provider == null || item.provider!.isEmpty)
                              ? 'Không rõ provider'
                              : item.provider!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.hasPassword ||
                      item.hasClientId ||
                      item.hasRefreshToken ||
                      item.hasTwoFactorSecret) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.hasPassword)
                          CredBadge(
                            icon: AmazingIconBulk.lock,
                            label: 'Password',
                          ),
                        if (item.hasClientId)
                          CredBadge(
                            icon: AmazingIconBulk.key,
                            label: 'Client ID',
                          ),
                        if (item.hasRefreshToken)
                          CredBadge(
                            icon: AmazingIconBulk.refresh,
                            label: 'Refresh Token',
                          ),
                        if (item.hasTwoFactorSecret)
                          CredBadge(
                            icon: AmazingIconBulk.security,
                            label: '2FA',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                  if (hasNotes) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
