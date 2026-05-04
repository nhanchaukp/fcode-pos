import 'package:fcode_pos/models/icallme_voucher.dart';
import 'package:fcode_pos/services/icallme_voucher_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IcallmeVoucherDetailScreen extends StatefulWidget {
  const IcallmeVoucherDetailScreen({required this.voucherCode, super.key});

  final String voucherCode;

  @override
  State<IcallmeVoucherDetailScreen> createState() =>
      _IcallmeVoucherDetailScreenState();
}

class _IcallmeVoucherDetailScreenState
    extends State<IcallmeVoucherDetailScreen> {
  final _service = IcallmeVoucherService();

  IcallmeVoucher? _voucher;
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
      final res = await _service.show(widget.voucherCode);
      if (!mounted) return;
      setState(() {
        _voucher = res.data;
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

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.voucherCode));
    Toastr.success('Đã sao chép mã voucher', context: context);
  }

  Future<void> _revoke() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thu hồi voucher'),
        content: Text(
          'Bạn có chắc muốn thu hồi mã ${widget.voucherCode}?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _service.revoke(widget.voucherCode);
      if (!mounted) return;
      Toastr.success('Đã thu hồi voucher thành công', context: context);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Toastr.error(e.toString(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRevoke = _voucher?.status == IcallmeVoucherStatus.available;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Voucher'),
        actions: [
          if (canRevoke)
            IconButton(
              icon: Icon(Icons.block,
                  color: Theme.of(context).colorScheme.error),
              tooltip: 'Thu hồi voucher',
              onPressed: _revoke,
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Sao chép mã',
            onPressed: _copyCode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_voucher == null) return const SizedBox.shrink();

    return _VoucherDetail(voucher: _voucher!);
  }
}

// ---------------------------------------------------------------------------
// Detail view
// ---------------------------------------------------------------------------

class _VoucherDetail extends StatelessWidget {
  const _VoucherDetail({required this.voucher});

  final IcallmeVoucher voucher;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusColor, statusIcon) = _statusMeta(voucher.status, cs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code hero card
          _CodeCard(
            voucher: voucher,
            statusColor: statusColor,
            statusIcon: statusIcon,
          ),
          const SizedBox(height: 16),

          // Info section
          _Section(
            title: 'Thông tin',
            children: [
              _InfoRow(
                icon: Icons.star_outline,
                label: 'Premium',
                value: voucher.premiumDays == 9999
                    ? 'Lifetime'
                    : '${voucher.premiumDays} ngày',
                valueColor: cs.primary,
                bold: true,
              ),
              _InfoRow(
                icon: Icons.link_outlined,
                label: 'Ref ID',
                value: voucher.externalRefId,
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Tạo lúc',
                value: _formatDateTime(voucher.createdAt),
              ),
              _InfoRow(
                icon: voucher.isExpired
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
                label: 'Hết hạn',
                value: _formatDateTime(voucher.expiredAt),
                valueColor: voucher.isExpired ? Colors.red : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Redemption section
          _Section(
            title: 'Sử dụng',
            children: [
              _InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Trạng thái',
                value: voucher.status.label,
                valueColor: statusColor,
                bold: true,
              ),
              if (voucher.redeemedAt != null)
                _InfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Dùng lúc',
                  value: _formatDateTime(voucher.redeemedAt),
                ),
              if (voucher.redeemedByUserId != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'User ID',
                  value: voucher.redeemedByUserId!,
                  monospace: true,
                ),
              if (voucher.revokedAt != null)
                _InfoRow(
                  icon: Icons.cancel_outlined,
                  label: 'Thu hồi lúc',
                  value: _formatDateTime(voucher.revokedAt),
                  valueColor: Colors.red,
                ),
            ],
          ),

          // Metadata section
          if (voucher.externalMetadata != null &&
              voucher.externalMetadata!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Metadata',
              children: voucher.externalMetadata!.entries
                  .map(
                    (e) => _InfoRow(
                      icon: Icons.data_object_outlined,
                      label: e.key,
                      value: e.value?.toString() ?? '—',
                      monospace: true,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  (Color, IconData) _statusMeta(IcallmeVoucherStatus status, ColorScheme cs) {
    return switch (status) {
      IcallmeVoucherStatus.available =>
        (Colors.green, Icons.check_circle_outline),
      IcallmeVoucherStatus.used => (cs.primary, Icons.task_alt),
      IcallmeVoucherStatus.revoked => (Colors.red, Icons.cancel_outlined),
      IcallmeVoucherStatus.expired =>
        (Colors.orange, Icons.timer_off_outlined),
      _ => (cs.onSurfaceVariant, Icons.help_outline),
    };
  }
}

// ---------------------------------------------------------------------------
// Code hero card
// ---------------------------------------------------------------------------

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.voucher,
    required this.statusColor,
    required this.statusIcon,
  });

  final IcallmeVoucher voucher;
  final Color statusColor;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 28, color: statusColor),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: voucher.voucherCode));
                Toastr.success('Đã sao chép mã voucher', context: context);
              },
              child: Text(
                voucher.voucherCode,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.3), width: 0.8),
              ),
              child: Text(
                voucher.status.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              voucher.premiumDays == 9999
                  ? 'Lifetime Premium'
                  : '${voucher.premiumDays} ngày Premium',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section + InfoRow
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: valueColor ?? cs.onSurface,
                fontFamily: monospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
