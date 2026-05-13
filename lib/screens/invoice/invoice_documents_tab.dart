import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/invoice/invoice_detail_screen.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

/// Danh sách hóa đơn & quota — dùng trong [InvoiceListScreen].
class InvoiceDocumentsTab extends StatefulWidget {
  const InvoiceDocumentsTab({super.key});

  @override
  State<InvoiceDocumentsTab> createState() => InvoiceDocumentsTabState();
}

class InvoiceDocumentsTabState extends State<InvoiceDocumentsTab>
    with AutomaticKeepAliveClientMixin {
  final _service = InvoiceService();

  @override
  bool get wantKeepAlive => true;

  List<Invoice> _invoices = [];
  InvoiceQuota? _quota;
  bool _isLoading = false;
  bool _isQuotaLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  InvoiceStatus? _selectedStatus;

  static const List<InvoiceStatus?> _statusOptions = [
    null,
    InvoiceStatus.draft,
    InvoiceStatus.issued,
    InvoiceStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Gọi từ nút làm mới trên AppBar.
  Future<void> refreshAll() async {
    await Future.wait([_loadInvoices(page: 1), _loadQuota()]);
  }

  Future<void> _loadData() async {
    _loadInvoices(page: 1);
    _loadQuota();
  }

  Future<void> _loadInvoices({int? page}) async {
    final targetPage = page ?? _currentPage;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.listInvoices(
        page: targetPage,
        perPage: 15,
        status: _selectedStatus?.value,
      );
      if (!mounted) return;
      final pagination = res.data?.pagination;
      setState(() {
        _invoices = res.data?.items ?? [];
        _currentPage = pagination?.currentPage ?? 1;
        _totalPages = pagination?.lastPage ?? 1;
        _totalCount = pagination?.total ?? 0;
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

  Future<void> _loadQuota() async {
    setState(() => _isQuotaLoading = true);
    try {
      final res = await _service.getQuota();
      if (!mounted) return;
      setState(() {
        _quota = res.data;
        _isQuotaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isQuotaLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildTopSection(context),
            _buildStatusFilter(context),
            Expanded(child: _buildList(context)),
            _buildPagination(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Tổng hóa đơn',
              value: _isLoading ? '—' : '$_totalCount',
              icon: Icons.receipt_long_outlined,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Quota còn lại',
              value: _isQuotaLoading
                  ? '—'
                  : (_quota != null ? '${_quota!.quotaRemaining}' : '—'),
              icon: Icons.confirmation_number_outlined,
              color: _quotaColor(cs),
            ),
          ),
        ],
      ),
    );
  }

  Color _quotaColor(ColorScheme cs) {
    final q = _quota?.quotaRemaining;
    if (q == null) return cs.secondary;
    if (q <= 10) return Colors.red;
    if (q <= 50) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusFilter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _statusOptions.length,
        separatorBuilder: (context, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final value = _statusOptions[i];
          final label = value?.label ?? 'Tất cả';
          final selected = _selectedStatus == value;
          return FilterChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            onSelected: (_) {
              setState(() => _selectedStatus = value);
              _loadInvoices(page: 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isLoading && _invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Không có hóa đơn nào',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _invoices.length,
      itemBuilder: (context, index) => _InvoiceCard(invoice: _invoices[index]),
    );
  }

  Widget _buildPagination(BuildContext context) {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.applyOpacity(0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.outlined(
            onPressed: _currentPage > 1
                ? () => _loadInvoices(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            'Trang $_currentPage / $_totalPages',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          IconButton.outlined(
            onPressed: _currentPage < _totalPages
                ? () => _loadInvoices(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.applyOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = InvoiceStatus.fromValue(invoice.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InvoiceDetailScreen(referenceCode: invoice.referenceCode),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.buyer.name.isNotEmpty
                          ? invoice.buyer.name
                          : 'Khách lẻ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  EnumBadge(
                    value: status,
                    fallbackLabel: invoice.status,
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    borderRadius: 6,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.tag, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    invoice.invoiceNumber.isNotEmpty
                        ? 'Số ${invoice.invoiceNumber}'
                        : 'Chưa có số',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    DateHelper.formatDate(invoice.issuedDate),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AmountChip(
                    label: 'Trước thuế',
                    amount: invoice.totalBeforeTax,
                    color: cs.onSurfaceVariant,
                  ),
                  _AmountChip(
                    label: 'Thuế',
                    amount: invoice.taxAmount,
                    color: Colors.orange,
                  ),
                  _AmountChip(
                    label: 'Tổng cộng',
                    amount: invoice.totalAmount,
                    color: cs.primary,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final int amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          CurrencyHelper.formatCurrency(amount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
