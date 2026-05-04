import 'dart:convert';

import 'package:fcode_pos/models/icallme_voucher.dart';
import 'package:fcode_pos/screens/icallme/icallme_voucher_detail_screen.dart';
import 'package:fcode_pos/services/icallme_voucher_service.dart';
import 'package:flutter/material.dart';

class IcallmeVoucherScreen extends StatefulWidget {
  const IcallmeVoucherScreen({super.key});

  @override
  State<IcallmeVoucherScreen> createState() => _IcallmeVoucherScreenState();
}

class _IcallmeVoucherScreenState extends State<IcallmeVoucherScreen>
    with SingleTickerProviderStateMixin {
  final _service = IcallmeVoucherService();
  final _scrollController = ScrollController();

  late TabController _tabController;

  static const _tabs = [
    (label: 'Tất cả', status: null),
    (label: 'Khả dụng', status: 'available'),
    (label: 'Đã dùng', status: 'used'),
    (label: 'Thu hồi', status: 'revoked'),
    (label: 'Hết hạn', status: 'expired'),
  ];

  // Filters
  String _externalRefId = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<IcallmeVoucher> _items = [];
  IcallmeVoucherSummary? _summary;

  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _summaryLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) _resetAndLoad();
      });
    _scrollController.addListener(_onScroll);
    _loadSummary();
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _currentStatus => _tabs[_tabController.index].status;

  bool get _hasActiveFilters =>
      _externalRefId.isNotEmpty || _fromDate != null || _toDate != null;

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetch();
    }
  }

  void _resetAndLoad() {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    _fetch();
  }

  Future<void> _fetch() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.list(
        status: _currentStatus,
        externalRefId: _externalRefId.isEmpty ? null : _externalRefId,
        fromDate: _fromDate?.toUtc().toIso8601String(),
        toDate: _toDate?.toUtc().toIso8601String(),
        page: _page,
        limit: 20,
      );
      if (!mounted) return;
      final data = res.data;
      if (data == null) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _items.addAll(data.items);
        _hasMore = data.hasMore;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final res = await _service.summary();
      if (!mounted) return;
      setState(() {
        _summary = res.data;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  Future<void> _refresh() async {
    _loadSummary();
    _resetAndLoad();
  }

  void _showFilterSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        initialRefId: _externalRefId,
        initialFromDate: _fromDate,
        initialToDate: _toDate,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _externalRefId = result.externalRefId;
      _fromDate = result.fromDate;
      _toDate = result.toDate;
    });
    _resetAndLoad();
  }

  void _clearFilters() {
    setState(() {
      _externalRefId = '';
      _fromDate = null;
      _toDate = null;
    });
    _resetAndLoad();
  }

  void _openDetail(IcallmeVoucher voucher) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IcallmeVoucherDetailScreen(
          voucherCode: voucher.voucherCode,
        ),
      ),
    );
    if (refreshed == true) _resetAndLoad();
  }

  void _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CreateVoucherSheet(service: _service),
    );
    if (created == true) {
      _loadSummary();
      _resetAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) => _buildScaffold(context);

  Widget _buildScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Icallme Vouchers'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Bộ lọc',
                onPressed: _showFilterSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('Tạo Voucher'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _SummaryHeader(
                summary: _summary,
                isLoading: _summaryLoading,
              ),
            ),
            if (_hasActiveFilters)
              SliverToBoxAdapter(
                child: _ActiveFilterChips(
                  externalRefId: _externalRefId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onClear: _clearFilters,
                ),
              ),
            if (_error != null && _items.isEmpty)
              SliverFillRemaining(
                child: _ErrorView(error: _error!, onRetry: _resetAndLoad),
              )
            else if (_items.isEmpty && _isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _items.length) {
                      return _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                    return _VoucherTile(
                      voucher: _items[index],
                      onTap: () => _openDetail(_items[index]),
                    );
                  },
                  childCount: _items.length + (_isLoading || _hasMore ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter sheet
// ---------------------------------------------------------------------------

class _FilterResult {
  const _FilterResult({
    required this.externalRefId,
    this.fromDate,
    this.toDate,
  });

  final String externalRefId;
  final DateTime? fromDate;
  final DateTime? toDate;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialRefId,
    this.initialFromDate,
    this.initialToDate,
  });

  final String initialRefId;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TextEditingController _refIdController;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _refIdController = TextEditingController(text: widget.initialRefId);
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  @override
  void dispose() {
    _refIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _FilterResult(
        externalRefId: _refIdController.text.trim(),
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  void _reset() {
    setState(() {
      _refIdController.clear();
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Text(
                'Bộ lọc',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ref ID
          TextField(
            controller: _refIdController,
            decoration: InputDecoration(
              labelText: 'Ref ID (ORDER-xxx)',
              hintText: 'Ví dụ: ORDER-2129',
              prefixIcon: const Icon(Icons.link_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _refIdController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _refIdController.clear()),
                    )
                  : null,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Date range
          Text(
            'Khoảng thời gian tạo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Từ ngày',
                  value: _fromDate,
                  onTap: () => _pickDate(true),
                  onClear: _fromDate != null
                      ? () => setState(() => _fromDate = null)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DatePickerField(
                  label: 'Đến ngày',
                  value: _toDate,
                  onTap: () => _pickDate(false),
                  onClear: _toDate != null
                      ? () => setState(() => _toDate = null)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              child: const Text('Áp dụng'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  String _format(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value != null ? _format(value!) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active filter chips
// ---------------------------------------------------------------------------

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.externalRefId,
    required this.fromDate,
    required this.toDate,
    required this.onClear,
  });

  final String externalRefId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onClear;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chips = <String>[];
    if (externalRefId.isNotEmpty) chips.add('Ref: $externalRefId');
    if (fromDate != null) chips.add('Từ: ${_fmt(fromDate!)}');
    if (toDate != null) chips.add('Đến: ${_fmt(toDate!)}');

    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: chips
                  .map((c) => Chip(
                        label: Text(c,
                            style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Xóa', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create voucher sheet
// ---------------------------------------------------------------------------

enum _PackageId {
  personYear('person_year', 'Person – 1 năm'),
  personLifetime('person_lifetime', 'Person – Lifetime'),
  groupYear('group_year', 'Group – 1 năm'),
  groupLifetime('group_lifetime', 'Group – Lifetime');

  const _PackageId(this.value, this.label);
  final String value;
  final String label;
}

class _CreateVoucherSheet extends StatefulWidget {
  const _CreateVoucherSheet({required this.service});
  final IcallmeVoucherService service;

  @override
  State<_CreateVoucherSheet> createState() => _CreateVoucherSheetState();
}

class _CreateVoucherSheetState extends State<_CreateVoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _refIdController = TextEditingController();
  final _metaController = TextEditingController();

  _PackageId _package = _PackageId.personYear;
  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _refIdController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Map<String, dynamic>? meta;
    final metaText = _metaController.text.trim();
    if (metaText.isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(
          jsonDecode(metaText) as Map,
        );
      } catch (_) {
        setState(() => _saveError = 'Metadata không phải JSON hợp lệ');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.service.create(
        packageId: _package.value,
        externalRefId: _refIdController.text.trim(),
        externalMetadata: meta,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Tạo Voucher',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Package
            DropdownButtonFormField<_PackageId>(
              value: _package,
              decoration: InputDecoration(
                labelText: 'Gói *',
                prefixIcon: const Icon(Icons.card_membership_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: _PackageId.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _package = v!),
            ),
            const SizedBox(height: 12),

            // Ref ID
            TextFormField(
              controller: _refIdController,
              decoration: InputDecoration(
                labelText: 'Ref ID *',
                hintText: 'ORDER-xxx',
                prefixIcon: const Icon(Icons.link_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập Ref ID' : null,
            ),
            const SizedBox(height: 12),

            // Metadata JSON
            TextFormField(
              controller: _metaController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Metadata (JSON, tùy chọn)',
                hintText: '{"key": "value"}',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.data_object_outlined),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                alignLabelWithHint: true,
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),

            // Error
            if (_saveError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _saveError!,
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo Voucher'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary header
// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary, required this.isLoading});

  final IcallmeVoucherSummary? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (summary == null) return const SizedBox.shrink();

    final s = summary!;
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Tổng tạo',
                  value: '${s.totalCreated}',
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Đã dùng',
                  value: '${s.totalRedeemed}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Thu hồi',
                  value: '${s.totalRevoked}',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Khả dụng',
                  value: '${s.totalAvailable}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Tỷ lệ sử dụng: ${s.redemptionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              if (s.totalExpired > 0) ...[
                Icon(Icons.timer_off_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  '${s.totalExpired} hết hạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voucher tile
// ---------------------------------------------------------------------------

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({required this.voucher, required this.onTap});

  final IcallmeVoucher voucher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusColor, statusIcon) = _statusMeta(voucher.status, cs);

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
          children: [
            // Status dot
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 18, color: statusColor),
            ),
            const SizedBox(width: 12),

            // Code + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        voucher.voucherCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: voucher.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_outline,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${voucher.premiumDays == 9999 ? 'Lifetime' : '${voucher.premiumDays} ngày'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.link_outlined,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          voucher.externalRefId,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (voucher.expiredAt != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          voucher.isExpired
                              ? Icons.timer_off_outlined
                              : Icons.timer_outlined,
                          size: 12,
                          color: voucher.isExpired
                              ? Colors.red
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(voucher.expiredAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: voucher.isExpired
                                ? Colors.red
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  (Color, IconData) _statusMeta(IcallmeVoucherStatus status, ColorScheme cs) {
    return switch (status) {
      IcallmeVoucherStatus.available => (Colors.green, Icons.check_circle_outline),
      IcallmeVoucherStatus.used => (cs.primary, Icons.task_alt),
      IcallmeVoucherStatus.revoked => (Colors.red, Icons.cancel_outlined),
      IcallmeVoucherStatus.expired => (Colors.orange, Icons.timer_off_outlined),
      _ => (cs.onSurfaceVariant, Icons.help_outline),
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 52,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Không có voucher nào',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: cs.error.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
