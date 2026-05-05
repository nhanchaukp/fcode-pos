import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvoiceProviderDetailScreen extends StatefulWidget {
  const InvoiceProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  @override
  State<InvoiceProviderDetailScreen> createState() =>
      _InvoiceProviderDetailScreenState();
}

class _InvoiceProviderDetailScreenState
    extends State<InvoiceProviderDetailScreen> {
  final _service = InvoiceService();

  InvoiceProviderAccount? _account;
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
      final res = await _service.getProvider(widget.providerId);
      if (!mounted) return;
      setState(() {
        _account = res.data;
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

  static String _displayName(String code) => switch (code.toLowerCase()) {
    'matbao' => 'Mắt Bảo',
    'fpt' => 'FPT',
    'vnpt' => 'VNPT',
    _ => code.isEmpty ? '—' : code,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _account != null ? _displayName(_account!.provider) : 'NCC',
        ),
        actions: [
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
    final a = _account;
    if (a == null) {
      return const Center(child: Text('Không tìm thấy nhà cung cấp'));
    }

    final cs = Theme.of(context).colorScheme;
    final templates = a.templates;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayName(a.provider),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (a.active ? Colors.green : Colors.grey)
                            .applyOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.active ? 'Hoạt động' : 'Tắt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: a.active ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow(context, label: 'Mã hệ thống', value: a.provider),
                _detailRow(
                  context,
                  label: 'ID tài khoản',
                  value: a.id,
                  monospace: true,
                  trailing: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: a.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép ID'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Mẫu hóa đơn (${templates?.length ?? 0})',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (templates == null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Không có dữ liệu mẫu trong phản hồi — kéo làm mới để thử lại.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (templates.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.folder_open_outlined, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tài khoản này chưa có mẫu hóa đơn.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...templates.asMap().entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 15,
                  child: Text('${entry.key + 1}'),
                ),
                title: Text(
                  entry.value.invoiceLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _chip(
                        context,
                        Icons.code,
                        'Mẫu: ${entry.value.templateCode}',
                      ),
                      _chip(
                        context,
                        Icons.confirmation_number_outlined,
                        'Ký hiệu: ${entry.value.invoiceSeries}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool monospace = false,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
