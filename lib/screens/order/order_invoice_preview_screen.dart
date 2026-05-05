import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_upsert_screen.dart';
import 'package:fcode_pos/screens/order/order_create_invoice_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/ui/components/link_button.dart';
import 'package:flutter/material.dart';

class OrderInvoicePreviewScreen extends StatefulWidget {
  const OrderInvoicePreviewScreen({
    super.key,
    required this.orderId,
    this.taxRate,
  });

  final String orderId;
  final TaxRate? taxRate;

  @override
  State<OrderInvoicePreviewScreen> createState() =>
      _OrderInvoicePreviewScreenState();
}

class _OrderInvoicePreviewScreenState extends State<OrderInvoicePreviewScreen> {
  final _service = OrderService();
  OrderInvoicePreview? _preview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final previewRes = await _service.invoicePreview(
        widget.orderId,
        taxRate: widget.taxRate ?? TaxRate.noDeclaration,
      );
      if (!mounted) return;
      setState(() {
        _preview = previewRes.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreateInvoice() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderCreateInvoiceScreen(orderId: widget.orderId),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openBuyerUpdate() async {
    final userId = _preview?.buyer.id;
    if (userId == null) {
      Toastr.warning('Không có buyer.id để cập nhật.');
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerUpsertScreen(userId: userId)),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = _preview;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      floatingActionButton: p != null && !_loading
          ? FloatingActionButton.extended(
              onPressed: _openCreateInvoice,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Tạo hóa đơn'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('Preview HĐ #${widget.orderId}'),
            actions: [
              IconButton(
                onPressed: _loading ? null : _load,
                icon: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurface,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Tải lại',
              ),
            ],
          ),
          if (_loading && p == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorView(error: _error!, onRetry: _load),
            )
          else if (p == null)
            const SliverFillRemaining(
              child: Center(child: Text('Không có dữ liệu preview')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
              sliver: SliverList.list(
                children: [
                  _OverviewCard(preview: p),
                  const SizedBox(height: 12),
                  _BuyerCard(buyer: p.buyer, onEdit: _openBuyerUpdate),
                  if (p.existingInvoice != null) ...[
                    const SizedBox(height: 12),
                    _ExistingInvoiceCard(invoice: p.existingInvoice!),
                  ],
                  const SizedBox(height: 12),
                  _ItemsSection(items: p.items),
                  const SizedBox(height: 12),
                  _SummaryCard(summary: p.summary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Overview card ────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.preview});
  final OrderInvoicePreview preview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = preview.defaults;
    final isDraft = d.isDraft;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 22,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng #${preview.orderId}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Chip(
                        label: d.currency?.label ?? d.currencyValue,
                        icon: Icons.currency_exchange_rounded,
                      ),
                      _Chip(
                        label: d.taxRate?.label ?? 'N/A',
                        icon: Icons.percent_rounded,
                      ),
                      _Chip(
                        label: isDraft ? 'Nháp' : 'Chính thức',
                        icon: isDraft
                            ? Icons.edit_note_rounded
                            : Icons.verified_rounded,
                        color: isDraft ? cs.tertiary : cs.primary,
                        bgColor: isDraft
                            ? cs.tertiaryContainer
                            : cs.primaryContainer,
                      ),
                    ],
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

// ─── Buyer card ───────────────────────────────────────────────────────────────

class _BuyerCard extends StatelessWidget {
  const _BuyerCard({required this.buyer, required this.onEdit});
  final InvoiceBuyer buyer;
  final VoidCallback onEdit;

  String _v(String? v) {
    if (v == null) return '—';
    final t = v.trim();
    return t.isEmpty ? '—' : t;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông tin người mua',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                LinkButton(
                  onTap: onEdit,
                  icon: Icons.edit_rounded,
                  label: 'Cập nhật',
                  color: cs.primary,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _BuyerRow(
                  icon: Icons.badge_rounded,
                  label: 'Tên',
                  value: _v(buyer.name),
                  bold: true,
                ),
                _BuyerRow(
                  icon: Icons.business_rounded,
                  label: 'Tên pháp lý',
                  value: _v(buyer.legalName),
                ),
                _BuyerRow(
                  icon: Icons.tag_rounded,
                  label: 'Mã người mua',
                  value: _v(buyer.buyerCode),
                ),
                _BuyerRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Số định danh',
                  value: _v(buyer.nationalId),
                ),
                _BuyerRow(
                  icon: Icons.receipt_rounded,
                  label: 'Mã số thuế',
                  value: _v(buyer.taxCode),
                ),
                _BuyerRow(
                  icon: Icons.location_on_rounded,
                  label: 'Địa chỉ',
                  value: _v(buyer.address),
                ),
                _BuyerRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: _v(buyer.email),
                ),
                _BuyerRow(
                  icon: Icons.phone_rounded,
                  label: 'SĐT',
                  value: _v(buyer.phone),
                ),
                _BuyerRow(
                  icon: Icons.group_rounded,
                  label: 'Loại KH',
                  value: _v(buyer.buyerType?.label),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerRow extends StatelessWidget {
  const _BuyerRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEmpty = value == '—';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: isEmpty ? cs.outlineVariant : null,
                fontStyle: isEmpty ? FontStyle.italic : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Existing invoice banner ──────────────────────────────────────────────────

class _ExistingInvoiceCard extends StatelessWidget {
  const _ExistingInvoiceCard({required this.invoice});
  final OrderInvoiceExistingInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, size: 16, color: cs.tertiary),
              const SizedBox(width: 8),
              Text(
                'Hóa đơn đã tồn tại',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem('Reference', invoice.referenceCode),
              _InfoItem(
                'Mẫu / Ký hiệu',
                '${invoice.templateCode} · ${invoice.invoiceSeries}',
              ),
              _InfoItem('Trạng thái', invoice.status),
              _InfoItem(
                'Ngày phát hành',
                invoice.issuedDate != null
                    ? DateHelper.formatDateTime(invoice.issuedDate)
                    : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Items section ────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});
  final List<OrderInvoicePreviewItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Sản phẩm / Dịch vụ',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} dòng',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  _ItemRow(item: items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderInvoicePreviewItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.lineNumber}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.itemCode,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SmallTag(label: item.unitDisplay),
                      const SizedBox(width: 4),
                      _SmallTag(label: item.lineTypeLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              _priceRow(
                context,
                'SL × Đơn giá',
                '${item.quantity} × ${CurrencyHelper.formatCurrency(item.unitPrice)}',
              ),
              _priceRow(
                context,
                'Thuế suất',
                item.taxRateEnum?.label ?? '${item.taxRateValue}%',
              ),
              _priceRow(
                context,
                'Trước thuế',
                CurrencyHelper.formatCurrency(item.beforeDiscountAndTaxAmount),
              ),
              _priceRow(
                context,
                'Tiền thuế',
                CurrencyHelper.formatCurrency(item.taxAmount),
              ),
              const SizedBox(height: 4),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Thành tiền',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyHelper.formatCurrency(item.lineTotal),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final OrderInvoicePreviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.calculate_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Tổng tiền',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                _sumRow(
                  context,
                  label: 'Tạm tính',
                  value: CurrencyHelper.formatCurrency(summary.subtotal),
                ),
                _sumRow(
                  context,
                  label: 'Giảm giá',
                  value: '− ${CurrencyHelper.formatCurrency(summary.discount)}',
                  valueColor: cs.error,
                ),
                _sumRow(
                  context,
                  label: 'Sau giảm giá',
                  value: CurrencyHelper.formatCurrency(
                    summary.totalAfterDiscount,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Tổng cộng',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyHelper.formatCurrency(summary.orderTotal),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    this.color,
    this.bgColor,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSecondaryContainer;
    final bg = bgColor ?? cs.secondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 10,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onTertiaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: cs.onErrorContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tải được dữ liệu',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
