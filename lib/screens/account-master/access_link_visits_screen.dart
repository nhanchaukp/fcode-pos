import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';

class AccessLinkVisitsScreen extends StatefulWidget {
  const AccessLinkVisitsScreen({super.key, required this.accessLink});

  final AccessLink accessLink;

  @override
  State<AccessLinkVisitsScreen> createState() => _AccessLinkVisitsScreenState();
}

class _AccessLinkVisitsScreenState extends State<AccessLinkVisitsScreen> {
  final _service = AccountSlotService();

  PaginatedData<AccessLinkVisit>? _page;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;

  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = page;
    });
    try {
      final res = await _service.accessLinkVisits(
        widget.accessLink.id.toString(),
        page: page,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() => _page = res.data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _page = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(AccessLinkVisit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VisitDetailSheet(visit: visit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _page?.items ?? [];
    final pagination = _page?.pagination;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch sử truy cập'),
            Text(
              widget.accessLink.slug,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Làm mới',
            onPressed: _loading ? null : () => _load(page: _currentPage),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent(items)),
            _buildPagination(pagination),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<AccessLinkVisit> items) {
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
            Icon(Icons.travel_explore_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có lượt truy cập nào'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(page: _currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) =>
            _VisitCard(visit: items[i], onTap: () => _openDetail(items[i])),
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
            onPressed: !_loading && pagination.currentPage < pagination.lastPage
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

// ── Visit Card ────────────────────────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final AccessLinkVisit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visit.ipAddress ?? 'Không rõ IP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _LocationStatusBadge(status: visit.locationStatus),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      visit.hasLocation
                          ? visit.locationSummary
                          : (visit.locationMessage ?? 'Không có vị trí'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    visit.visitedAt != null
                        ? DateHelper.formatDateTime(visit.visitedAt!)
                        : '—',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (visit.shopOrderItemId != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 13,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '#${visit.shopOrderItemId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationStatusBadge extends StatelessWidget {
  const _LocationStatusBadge({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final ok = status?.toLowerCase() == 'success';
    final color = ok ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        (status == null || status!.isEmpty) ? 'N/A' : status!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Visit Detail Sheet ────────────────────────────────────────────────────────

class _VisitDetailSheet extends StatelessWidget {
  const _VisitDetailSheet({required this.visit});
  final AccessLinkVisit visit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.public, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      visit.ipAddress ?? 'Không rõ IP',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  _LocationStatusBadge(status: visit.locationStatus),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _section('Thời gian'),
                  _row('Truy cập lúc', _fmt(visit.visitedAt)),
                  _row('Tạo lúc', _fmt(visit.createdAt)),
                  _row('Cập nhật lúc', _fmt(visit.updatedAt)),
                  const SizedBox(height: 12),
                  _section('Liên kết'),
                  _row('ID', '#${visit.id}'),
                  _row('Access link ID', '${visit.accountSlotAccessLinkId}'),
                  _row('Account slot ID', visit.accountSlotId?.toString() ?? '—'),
                  _row(
                    'Shop order item ID',
                    visit.shopOrderItemId?.toString() ?? '—',
                  ),
                  _row('User ID', visit.userId?.toString() ?? '—'),
                  const SizedBox(height: 12),
                  _section('Thiết bị'),
                  _row('IP', visit.ipAddress ?? '—'),
                  _row('Referer', visit.referer ?? '—'),
                  _row('User agent', visit.userAgent ?? '—'),
                  const SizedBox(height: 12),
                  _section('Vị trí'),
                  _row('Provider', visit.locationProvider ?? '—'),
                  _row('Trạng thái', visit.locationStatus ?? '—'),
                  _row('Thông báo', visit.locationMessage ?? '—'),
                  _row('Quốc gia', visit.country ?? '—'),
                  _row('Mã quốc gia', visit.countryCode ?? '—'),
                  _row('Vùng', visit.regionName ?? visit.region ?? '—'),
                  _row('Thành phố', visit.city ?? '—'),
                  _row('Zip', visit.zip ?? '—'),
                  _row(
                    'Toạ độ',
                    (visit.lat != null && visit.lon != null)
                        ? '${visit.lat}, ${visit.lon}'
                        : '—',
                  ),
                  _row('Timezone', visit.timezone ?? '—'),
                  _row('ISP', visit.isp ?? '—'),
                  _row('Tổ chức', visit.org ?? '—'),
                  _row('AS', visit.asInfo ?? '—'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _fmt(DateTime? dt) =>
      dt != null ? DateHelper.formatDateTime(dt) : '—';

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 2),
    child: Builder(
      builder: (context) => Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Builder(
            builder: (context) => Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
