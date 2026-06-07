import 'dart:convert';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/ui/components/app_tab.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/utils/string_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountSlotDetailScreen extends StatefulWidget {
  final AccountSlot slot;

  const AccountSlotDetailScreen({super.key, required this.slot});

  @override
  State<AccountSlotDetailScreen> createState() =>
      _AccountSlotDetailScreenState();
}

class _AccountSlotDetailScreenState extends State<AccountSlotDetailScreen>
    with SingleTickerProviderStateMixin {
  final _slotService = AccountSlotService();
  final _masterService = AccountMasterService();

  late TabController _tabController;
  late AccountSlot _slot;
  bool _loading = false;

  // Audit log state
  final List<Auditable> _audits = [];
  int _auditPage = 1;
  bool _auditLoading = false;
  bool _auditHasMore = true;
  bool _auditLoaded = false;
  String? _auditError;
  final _auditScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _slot = widget.slot;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _auditScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_auditLoaded && !_auditLoading) {
      _fetchAudits();
    }
  }

  // ── Data fetching ───────────────────────────────────────────────────────────

  Future<void> _fetchDetail() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final response = await _slotService.detail(_slot.id.toString());
      if (!mounted) return;
      setState(() {
        _slot = response.data ?? _slot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchAudits() async {
    if (_auditLoading || !_auditHasMore) return;
    setState(() {
      _auditLoading = true;
      _auditError = null;
    });
    try {
      final res = await _slotService.audits(_slot.id, page: _auditPage);
      if (!mounted) return;
      final data = res.data;
      if (data == null) {
        setState(() {
          _auditHasMore = false;
          _auditLoading = false;
          _auditLoaded = true;
        });
        return;
      }
      setState(() {
        _audits.addAll(data.items);
        _auditHasMore = data.pagination.currentPage < data.pagination.lastPage;
        _auditPage++;
        _auditLoading = false;
        _auditLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _auditError = e.toString();
        _auditLoading = false;
        _auditLoaded = true;
      });
    }
  }

  Future<void> _refreshAudits() async {
    setState(() {
      _audits.clear();
      _auditPage = 1;
      _auditHasMore = true;
      _auditLoaded = false;
      _auditError = null;
    });
    await _fetchAudits();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _unlinkOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ liên kết đơn hàng'),
        content: const Text(
          'Bạn có chắc muốn gỡ liên kết đơn hàng khỏi slot này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gỡ liên kết'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final response = await _slotService.unlinkOrder(_slot.id.toString());
      if (!mounted) return;
      if (response.success) {
        Toastr.success('Đã gỡ liên kết đơn hàng', context: context);
        _fetchDetail();
      } else {
        Toastr.error(
          response.message ?? 'Gỡ liên kết thất bại',
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi: ${e.toString()}', context: context);
      }
    }
  }

  Future<void> _copySlotInfo() async {
    final text = StringHelper.formatSlotCopyText(_slot);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) Toastr.success('Đã copy thông tin slot', context: context);
  }

  void _showCreateAccessLinkSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          _CreateAccessLinkSheet(slot: _slot, slotService: _slotService),
    ).then((created) {
      if (created == true && mounted) _fetchDetail();
    });
  }

  void _showEditSlot() async {
    final result = await showModalBottomSheet<AccountSlot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          _EditSlotSheet(slot: _slot, accountMasterService: _masterService),
    );
    if (result != null && mounted) {
      setState(() => _slot = result);
    }
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _hasOrder => _slot.shopOrderItem?.order != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _loading
              ? 'Đang tải...'
              : _slot.accountMaster != null
              ? '${_slot.name} • ${_slot.accountMaster!.name}'
              : _slot.name,
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<_SlotAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _SlotAction.copy:
                    _copySlotInfo();
                  case _SlotAction.edit:
                    _showEditSlot();
                  case _SlotAction.unlinkOrder:
                    _unlinkOrder();
                  case _SlotAction.viewOrder:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(
                          orderId: _slot.shopOrderItem!.orderId.toString(),
                        ),
                      ),
                    );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _SlotAction.copy,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.copy, size: 18),
                    title: Text('Sao chép thông tin'),
                  ),
                ),
                const PopupMenuItem(
                  value: _SlotAction.edit,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                if (_hasOrder) ...[
                  const PopupMenuItem(
                    value: _SlotAction.viewOrder,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.receipt_long, size: 18),
                      title: Text('Xem đơn hàng'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: _SlotAction.unlinkOrder,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.link_off, size: 18),
                      title: Text('Gỡ liên kết đơn hàng'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildInfoHeader()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        AppTab(icon: Icons.link, text: 'Access Links'),
                        AppTab(icon: Icons.history, text: 'Audit Log'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildAccessLinksTab(), _buildAuditTab()],
              ),
            ),
    );
  }

  // ── Skeleton ────────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeletonCard(lines: 6),
        const SizedBox(height: 16),
        _skeletonCard(lines: 3),
        const SizedBox(height: 16),
        _skeletonCard(lines: 4),
      ],
    );
  }

  Widget _skeletonCard({required int lines}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines, (i) {
            final isLast = i == lines - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _SkeletonBox(
                width: i == 0 ? 160 : (i % 2 == 0 ? double.infinity : 220),
                height: i == 0 ? 18 : 13,
                radius: 6,
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Info header (compact, outside tabs) ────────────────────────────────────

  Widget _buildInfoHeader() {
    final order = _slot.shopOrderItem?.order;
    final user = order?.user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status + PIN row ─────────────────────────────────────────────
          Row(
            children: [
              _StatusChip(isActive: _slot.isActive),
              if (_slot.pin.isNotEmpty) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _slot.pin));
                    Toastr.success('Đã sao chép PIN', context: context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 12,
                          color: _cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _slot.pin,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _cs.onSurface,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 11, color: _cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // ── Date fields ──────────────────────────────────────────────────
          _infoRow(
            Icons.date_range_outlined,
            'Ngày',
            '${DateHelper.formatDate(_slot.startDate)}  →  ${DateHelper.formatDate(_slot.expiryDate)}',
          ),
          _infoRow(
            Icons.timelapse_outlined,
            'Thời hạn',
            '${_slot.durationMonths} tháng',
          ),

          // ── Notes ────────────────────────────────────────────────────────
          if (_slot.notes != null && _slot.notes!.isNotEmpty)
            _infoRow(Icons.notes_outlined, 'Ghi chú', _slot.notes!),

          // ── Customer row ─────────────────────────────────────────────────
          if (_slot.shopOrderItem != null &&
              (user != null || order != null)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 13,
                  color: _cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user?.name ?? 'Không xác định',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user != null)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 12),
                    label: const Text('Hồ sơ'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (order != null)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(
                          orderId: _slot.shopOrderItem!.orderId.toString(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 12),
                    label: const Text('Đơn'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _cs.onSurfaceVariant),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: _cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: Access Links ───────────────────────────────────────────────────────

  Widget _buildAccessLinksTab() {
    final links = _slot.accessLinks ?? [];
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Header row: count badge + create button
          Row(
            children: [
              Icon(Icons.link, size: 16, color: _cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Access Links',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${links.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _cs.onSecondaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateAccessLinkSheet,
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Tạo link'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (links.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.link_off, size: 40, color: _cs.outlineVariant),
                      const SizedBox(height: 10),
                      Text(
                        'Chưa có access link nào',
                        style: TextStyle(
                          fontSize: 13,
                          color: _cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...links.map((link) => _AccessLinkCard(link: link)),
        ],
      ),
    );
  }

  // ── Tab: Audit Log ──────────────────────────────────────────────────────────

  Widget _buildAuditTab() {
    return RefreshIndicator(
      onRefresh: _refreshAudits,
      child: _buildAuditBody(),
    );
  }

  Widget _buildAuditBody() {
    if (_auditError != null && _audits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: _cs.error),
              const SizedBox(height: 12),
              Text(_auditError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _refreshAudits,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_audits.isEmpty && _auditLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_audits.isEmpty && !_auditLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 52,
              color: _cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử thay đổi',
              style: TextStyle(color: _cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
            !_auditLoading &&
            _auditHasMore) {
          _fetchAudits();
        }
        return false;
      },
      child: ListView.builder(
        controller: _auditScrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: _audits.length + (_auditHasMore || _auditLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _audits.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _AuditTile(
            audit: _audits[index],
            isLast: index == _audits.length - 1,
          );
        },
      ),
    );
  }
}

// ── Enum for popup menu actions ───────────────────────────────────────────────

enum _SlotAction { copy, edit, unlinkOrder, viewOrder }

// ── Skeleton box ─────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── AccessLink Card ───────────────────────────────────────────────────────────

class _AccessLinkCard extends StatelessWidget {
  final AccessLink link;

  const _AccessLinkCard({required this.link});

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        Toastr.error('Không thể mở liên kết', context: context);
      }
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link.url));
    Toastr.success('Đã sao chép URL', context: context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + ID
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: link.isActive ? Colors.green : cs.error,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  link.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: link.isActive ? Colors.green : cs.error,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${link.id}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // URL
            GestureDetector(
              onTap: () => _openUrl(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        link.url,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Slug
            Row(
              children: [
                Icon(Icons.tag, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    link.slug,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (link.createdAt != null)
              Text(
                'Tạo lúc: ${DateHelper.formatDateTime(link.createdAt)}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyUrl(context),
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy URL'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openUrl(context),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Mở URL'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (link.shopOrderId != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            orderId: link.shopOrderId.toString(),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 14),
                      label: const Text('Đơn hàng'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : cs.error,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Hoạt động' : 'Tạm dừng',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : cs.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ── TabBar pinned delegate ────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ── Create Access Link Sheet ──────────────────────────────────────────────────

class _CreateAccessLinkSheet extends StatefulWidget {
  final AccountSlot slot;
  final AccountSlotService slotService;

  const _CreateAccessLinkSheet({required this.slot, required this.slotService});

  @override
  State<_CreateAccessLinkSheet> createState() => _CreateAccessLinkSheetState();
}

class _CreateAccessLinkSheetState extends State<_CreateAccessLinkSheet> {
  bool _deactivateExisting = false;
  bool _isSubmitting = false;

  Future<void> _handleCreate() async {
    setState(() => _isSubmitting = true);
    try {
      final response = await widget.slotService.createAccessLink(
        widget.slot.id.toString(),
        deactiveExisting: _deactivateExisting,
      );
      if (!mounted) return;
      if (response.success) {
        Toastr.success('Đã tạo access link', context: context);
        Navigator.of(context).pop(true);
      } else {
        Toastr.error(response.message ?? 'Tạo thất bại', context: context);
      }
    } catch (e) {
      if (mounted) Toastr.error('Lỗi: ${e.toString()}', context: context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeCount =
        widget.slot.accessLinks?.where((l) => l.isActive).length ?? 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_link, color: cs.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tạo Access Link mới',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.slot.name,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Deactivate existing switch
            Material(
              color: _deactivateExisting
                  ? cs.errorContainer.withValues(alpha: 0.5)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _deactivateExisting
                        ? cs.error.withValues(alpha: 0.3)
                        : cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Vô hiệu hóa link hiện tại',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    activeCount > 0
                        ? '$activeCount link đang hoạt động sẽ bị deactivate'
                        : 'Không có link nào đang hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      color: _deactivateExisting
                          ? cs.error
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  value: _deactivateExisting,
                  onChanged: (v) => setState(() => _deactivateExisting = v),
                  activeColor: cs.error,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleCreate,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_link, size: 18),
              label: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo Access Link'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Edit Slot Sheet ───────────────────────────────────────────────────────────

class _EditSlotSheet extends StatefulWidget {
  final AccountSlot slot;
  final AccountMasterService accountMasterService;

  const _EditSlotSheet({
    required this.slot,
    required this.accountMasterService,
  });

  @override
  State<_EditSlotSheet> createState() => _EditSlotSheetState();
}

class _EditSlotSheetState extends State<_EditSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.slot.name);
    _pinController = TextEditingController(text: widget.slot.pin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await widget.accountMasterService.updateSlot(
        widget.slot.id,
        name: _nameController.text.trim(),
        pin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
      );
      if (!mounted) return;
      if (response.success && response.data != null) {
        Toastr.success('Cập nhật slot thành công', context: context);
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error(response.message ?? 'Cập nhật thất bại', context: context);
      }
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: ${e.toString()}', context: context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Chỉnh sửa slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên slot *',
                  hintText: 'Nhập tên slot',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên slot';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Nhập PIN (không bắt buộc)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: LoadingIcon(
                  icon: Icons.check_circle_outline_outlined,
                  loading: _isSubmitting,
                ),
                label: Text(_isSubmitting ? 'Đang cập nhật...' : 'Cập nhật'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Audit Tile ────────────────────────────────────────────────────────────────

class _AuditTile extends StatefulWidget {
  const _AuditTile({required this.audit, required this.isLast});

  final Auditable audit;
  final bool isLast;

  @override
  State<_AuditTile> createState() => _AuditTileState();
}

class _AuditTileState extends State<_AuditTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audit = widget.audit;
    final (eventColor, eventIcon, eventLabel) = _eventMeta(audit.event, cs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 56,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: eventColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(eventIcon, size: 16, color: eventColor),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: 16,
                top: 8,
                bottom: widget.isLast ? 8 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _EventBadge(label: eventLabel, color: eventColor),
                      const Spacer(),
                      _TimeText(audit.createdAt),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (audit.user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _UserChip(user: audit.user!),
                    ),
                  if (audit.event == 'updated' &&
                      (audit.oldValues?.isNotEmpty == true ||
                          audit.newValues?.isNotEmpty == true))
                    _DiffCard(
                      oldValues: audit.oldValues ?? {},
                      newValues: audit.newValues ?? {},
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                    )
                  else if (audit.event == 'created' &&
                      audit.newValues?.isNotEmpty == true)
                    _ValuesCard(
                      values: audit.newValues!,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                      label: 'Giá trị khởi tạo',
                      color: Colors.green,
                    )
                  else if (audit.event == 'deleted' &&
                      audit.oldValues?.isNotEmpty == true)
                    _ValuesCard(
                      values: audit.oldValues!,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                      label: 'Giá trị trước xóa',
                      color: Colors.red,
                    ),
                  if (audit.ipAddress != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language,
                          size: 11,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          audit.ipAddress!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(Color, IconData, String) _eventMeta(String event, ColorScheme cs) {
  return switch (event.toLowerCase()) {
    'created' => (Colors.green, Icons.add_circle_outline, 'Tạo mới'),
    'updated' => (Colors.orange, Icons.edit_outlined, 'Cập nhật'),
    'deleted' => (Colors.red, Icons.delete_outline, 'Xóa'),
    'restored' => (Colors.blue, Icons.restore, 'Khôi phục'),
    _ => (cs.primary, Icons.history, event),
  };
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText(this.rawDate);

  final String? rawDate;

  @override
  Widget build(BuildContext context) {
    if (rawDate == null) return const SizedBox.shrink();
    DateTime dt;
    try {
      dt = DateTime.parse(rawDate!).toLocal();
    } catch (_) {
      return Text(
        rawDate!,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final relative = _relativeTime(dt);
    final absolute =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Tooltip(
      message: absolute,
      child: Text(
        relative,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: cs.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          user.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DiffCard extends StatelessWidget {
  const _DiffCard({
    required this.oldValues,
    required this.newValues,
    required this.expanded,
    required this.onToggle,
  });

  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allKeys = {...oldValues.keys, ...newValues.keys}.toList();
    final changed = allKeys
        .where((k) => _str(oldValues[k]) != _str(newValues[k]))
        .toList();
    final shown = expanded ? changed : changed.take(2).toList();

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...shown.map(
              (key) => _DiffRow(
                fieldKey: key,
                oldVal: _str(oldValues[key]),
                newVal: _str(newValues[key]),
              ),
            ),
            if (changed.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expanded
                      ? 'Thu gọn'
                      : '+ ${changed.length - 2} thay đổi nữa...',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _str(dynamic val) {
    if (val == null) return '—';
    if (val is Map || val is List) return jsonEncode(val);
    return val.toString();
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.fieldKey,
    required this.oldVal,
    required this.newVal,
  });

  final String fieldKey;
  final String oldVal;
  final String newVal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldKey.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    oldVal,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 12, color: cs.onSurfaceVariant),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    newVal,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValuesCard extends StatelessWidget {
  const _ValuesCard({
    required this.values,
    required this.expanded,
    required this.onToggle,
    required this.label,
    required this.color,
  });

  final Map<String, dynamic> values;
  final bool expanded;
  final VoidCallback onToggle;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = values.entries.toList();
    final shown = expanded ? entries : entries.take(3).toList();

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...shown.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _str(e.value),
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entries.length > 3)
              Text(
                expanded ? 'Thu gọn' : '+ ${entries.length - 3} trường nữa...',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _str(dynamic val) {
    if (val == null) return '—';
    if (val is Map || val is List) return jsonEncode(val);
    return val.toString();
  }
}
