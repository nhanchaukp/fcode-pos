import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/invoice/invoice_provider_detail_screen.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class InvoiceProvidersTab extends StatefulWidget {
  const InvoiceProvidersTab({super.key});

  @override
  State<InvoiceProvidersTab> createState() => InvoiceProvidersTabState();
}

class InvoiceProvidersTabState extends State<InvoiceProvidersTab>
    with AutomaticKeepAliveClientMixin {
  final _service = InvoiceService();

  @override
  bool get wantKeepAlive => true;

  List<InvoiceProviderAccount> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load(page: 1);

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _currentPage;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.listProviders(
        page: targetPage,
        perPage: 20,
      );
      if (!mounted) return;
      final pagination = res.data?.pagination;
      setState(() {
        _items = res.data?.items ?? [];
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _load(page: 1),
        child: Column(
          children: [
            _buildSummary(context),
            Expanded(child: _buildList(context)),
            _buildPagination(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.applyOpacity(0.6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài khoản nhà cung cấp',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoading ? '—' : '$_totalCount kết nối',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
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
              onPressed: () => _load(page: 1),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Chưa có nhà cung cấp nào',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) =>
          _ProviderCard(account: _items[index]),
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
                ? () => _load(page: _currentPage - 1)
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
                ? () => _load(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.account});

  final InvoiceProviderAccount account;

  static String _displayName(String code) => switch (code.toLowerCase()) {
        'matbao' => 'Mã Bảo',
        _ => code.isEmpty ? '—' : code,
      };

  static Color _colorFor(String provider) =>
      switch (provider.toLowerCase()) {
        'matbao' => Colors.deepPurple,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = _colorFor(account.provider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceProviderDetailScreen(providerId: account.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint.applyOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.link, color: tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(account.provider),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.provider,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
              _ActivePill(active: account.active),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.applyOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Hoạt động' : 'Tắt',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
