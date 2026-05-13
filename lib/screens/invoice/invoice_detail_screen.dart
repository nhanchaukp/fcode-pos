import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/invoice/invoice_pdf_screen.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.referenceCode});

  final String referenceCode;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _service = InvoiceService();

  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.getInvoice(widget.referenceCode);
      if (!mounted) return;
      setState(() {
        _invoice = res.data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoice != null && _invoice!.invoiceNumber.isNotEmpty
                  ? 'Hóa đơn #${_invoice!.invoiceNumber}'
                  : 'Chi tiết hóa đơn',
            ),
            Text(
              widget.referenceCode,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (_invoice != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Sao chép mã tham chiếu',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _invoice!.referenceCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mã tham chiếu'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
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
            FilledButton.tonal(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_invoice == null) {
      return const Center(child: Text('Không tìm thấy hóa đơn'));
    }

    final inv = _invoice!;
    final invoiceStatus = InvoiceStatus.fromValue(inv.status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _buildStatusHeader(context, inv, invoiceStatus),
        const SizedBox(height: 10),
        _buildInfoSection(context, inv),
        const SizedBox(height: 10),
        _buildBuyerSection(context, inv.buyer),
        const SizedBox(height: 10),
        if (inv.items != null && inv.items!.isNotEmpty) ...[
          _buildItemsSection(context, inv.items!),
          const SizedBox(height: 10),
        ],
        _buildTotalsSection(context, inv),
        if (inv.notes != null && inv.notes!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildNotesSection(context, inv.notes!),
        ],
        if (inv.pdfUrl != null || inv.xmlUrl != null) ...[
          const SizedBox(height: 10),
          _buildLinksSection(context, inv),
        ],
        if (invoiceStatus == InvoiceStatus.draft) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _deleteDraft,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Xóa hóa đơn nháp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    Invoice inv,
    InvoiceStatus? status,
  ) {
    final statusColor = status?.color ?? Colors.grey;
    final statusIcon = status?.icon ?? Icons.help_outline;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.applyOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.invoiceNumber.isNotEmpty
                        ? 'Số hóa đơn: ${inv.invoiceNumber}'
                        : 'Chưa có số hóa đơn',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateHelper.formatDate(inv.issuedDate),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            EnumBadge(
              value: status,
              fallbackLabel: inv.status,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Invoice inv) {
    return _DetailCard(
      title: 'Thông tin hóa đơn',
      icon: Icons.receipt_outlined,
      children: [
        _InfoRow(
          label: 'Mã tham chiếu',
          value: inv.referenceCode,
          monospace: true,
          canCopy: true,
        ),
        _InfoRow(
          label: 'Ngày phát hành',
          value: DateHelper.formatDate(inv.issuedDate),
        ),
      ],
    );
  }

  Widget _buildBuyerSection(BuildContext context, InvoiceBuyer buyer) {
    return _DetailCard(
      title: 'Thông tin người mua',
      icon: Icons.business_outlined,
      children: [
        _InfoRow(label: 'Tên', value: buyer.name),
        if (buyer.taxCode != null && buyer.taxCode!.isNotEmpty)
          _InfoRow(label: 'Mã số thuế', value: buyer.taxCode!),
        if (buyer.address != null && buyer.address!.isNotEmpty)
          _InfoRow(label: 'Địa chỉ', value: buyer.address!),
        if (buyer.email != null && buyer.email!.isNotEmpty)
          _InfoRow(label: 'Email', value: buyer.email!),
        if (buyer.phone != null && buyer.phone!.isNotEmpty)
          _InfoRow(label: 'Điện thoại', value: buyer.phone!),
      ],
    );
  }

  Widget _buildItemsSection(BuildContext context, List<InvoiceItem> items) {
    final cs = Theme.of(context).colorScheme;
    return _DetailCard(
      title: 'Danh sách hàng hóa / dịch vụ',
      icon: Icons.list_alt_outlined,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Tên hàng hóa',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'SL × Đơn giá',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Thành tiền',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.applyOpacity(0.4)),
        ...items.map((item) => _ItemRow(item: item, colorScheme: cs)),
      ],
    );
  }

  Widget _buildTotalsSection(BuildContext context, Invoice inv) {
    final cs = Theme.of(context).colorScheme;
    return _DetailCard(
      title: 'Tổng tiền',
      icon: Icons.calculate_outlined,
      children: [
        _TotalRow(
          label: 'Tiền trước thuế',
          amount: inv.totalBeforeTax,
          color: cs.onSurface,
        ),
        _TotalRow(
          label: 'Tiền thuế GTGT',
          amount: inv.taxAmount,
          color: Colors.orange,
        ),
        Divider(height: 16, color: cs.outlineVariant.applyOpacity(0.4)),
        _TotalRow(
          label: 'Tổng cộng',
          amount: inv.totalAmount,
          color: cs.primary,
          bold: true,
          large: true,
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, String notes) {
    final cs = Theme.of(context).colorScheme;
    return _DetailCard(
      title: 'Ghi chú',
      icon: Icons.sticky_note_2_outlined,
      children: [
        Text(
          notes,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildLinksSection(BuildContext context, Invoice inv) {
    return _DetailCard(
      title: 'Tệp đính kèm',
      icon: Icons.attach_file_outlined,
      children: [
        if (inv.pdfUrl != null) ...[
          _LinkTile(
            label: 'Xem PDF',
            icon: Icons.visibility_outlined,
            color: Colors.deepPurple,
            url: inv.pdfUrl!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePdfScreen(
                    url: inv.pdfUrl!,
                    title: inv.invoiceNumber.isNotEmpty
                        ? 'HĐ #${inv.invoiceNumber}'
                        : null,
                  ),
                ),
              );
            },
          ),
          _LinkTile(
            label: 'Tải PDF',
            icon: Icons.picture_as_pdf_outlined,
            color: Colors.red,
            url: inv.pdfUrl!,
          ),
        ],
        if (inv.xmlUrl != null)
          _LinkTile(
            label: 'Tải XML',
            icon: Icons.code_outlined,
            color: Colors.blue,
            url: inv.xmlUrl!,
          ),
      ],
    );
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        title: const Text('Xóa hóa đơn nháp'),
        content: const Text(
          'Xác nhận xóa hóa đơn nháp này?\nThao tác không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang xóa hóa đơn…'),
            ],
          ),
        ),
      ),
    );

    try {
      await _service.deleteDraftInvoice(widget.referenceCode);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      Toastr.success('Đã xóa hóa đơn nháp.');
      Navigator.of(context).pop(true); // back to list
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      Toastr.error('$e');
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.canCopy = false,
  });

  final String label;
  final String value;
  final bool monospace;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: monospace ? 'monospace' : null,
                    ),
                  ),
                ),
                if (canCopy)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
    this.large = false,
  });

  final String label;
  final int amount;
  final Color color;
  final bool bold;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style =
        (large
                ? Theme.of(context).textTheme.bodyMedium
                : Theme.of(context).textTheme.bodySmall)
            ?.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            CurrencyHelper.formatCurrency(amount),
            style: style?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.colorScheme});

  final InvoiceItem item;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final qty = item.quantityValue;
    final price = item.unitPriceValue;
    final total = item.totalAmountValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.itemCode != null)
                  Text(
                    item.itemCode!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (item.unit != null)
                  Text(
                    'ĐVT: ${item.unit}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_fmtNum(qty)} × ${CurrencyHelper.formatCurrency(price.round())}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CurrencyHelper.formatCurrency(total.round()),
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtNum(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.applyOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label),
      trailing: Icon(
        onTap != null ? Icons.chevron_right : Icons.open_in_new_outlined,
        size: 16,
      ),
      onTap: onTap ?? () => openUrl(url),
    );
  }
}
