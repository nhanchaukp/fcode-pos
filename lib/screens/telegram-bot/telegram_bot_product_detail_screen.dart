import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_order_detail_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_product_edit_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotProductDetailScreen extends StatefulWidget {
  const TelegramBotProductDetailScreen({
    super.key,
    required this.token,
    required this.productId,
    this.initialProduct,
  });

  final String token;
  final int productId;
  final JsonMap? initialProduct;

  @override
  State<TelegramBotProductDetailScreen> createState() =>
      _TelegramBotProductDetailScreenState();
}

class _TelegramBotProductDetailScreenState
    extends State<TelegramBotProductDetailScreen> {
  static const _inventoryStatuses = <String>[
    '',
    'available',
    'reserved',
    'sold',
  ];

  late final TelegramBotApiClient _api;

  bool _isLoading = true;
  String? _error;
  JsonMap? _product;
  JsonMap _inventory = const {};
  List<JsonMap> _relatedOrders = const [];
  String _inventoryStatus = '';

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    _product = widget.initialProduct;
    _loadData();
  }

  bool get _isDucViet {
    final provider = (_product?['external_provider'] ?? 'LOCAL')
        .toString()
        .toUpperCase();
    return provider == 'DUCVIET';
  }

  bool get _isManual {
    return (_product?['delivery_type'] ?? 'AUTO').toString().toUpperCase() ==
        'MANUAL';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts();
      final product = products.firstWhere(
        (row) => _toInt(row['id']) == widget.productId,
        orElse: () => const {},
      );

      if (product.isEmpty) {
        throw TelegramBotApiException(
          'Không tìm thấy sản phẩm #${widget.productId}',
        );
      }

      final isDucViet =
          (product['external_provider'] ?? 'LOCAL').toString().toUpperCase() ==
          'DUCVIET';

      JsonMap inventory = const {};
      if (!isDucViet) {
        inventory = await _api.getProductInventory(
          widget.productId,
          status: _inventoryStatus.isEmpty ? null : _inventoryStatus,
          limit: 200,
        );
      }

      final orders = await _api.getOrders(limit: 300);
      final relatedOrders = orders
          .where((row) => _toInt(row['product_id']) == widget.productId)
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _product = product;
        _inventory = inventory;
        _relatedOrders = relatedOrders;
      });
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải chi tiết sản phẩm';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEdit() async {
    final product = _product;
    if (product == null) {
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelegramBotProductEditScreen(token: widget.token, product: product),
      ),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Future<void> _importAutoInventory() async {
    final controller = TextEditingController();

    final lines = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import tồn kho AUTO'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(hintText: 'acc1|pass1\nacc2|pass2'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (lines == null || lines.isEmpty) {
      return;
    }

    try {
      final result = await _api.importProductInventory(
        widget.productId,
        lines: lines,
      );
      final added = _toInt(result['added']);
      final totalAvailable = _toInt(result['totalAvailable']);
      Toastr.success('Đã import $added items. Tồn khả dụng: $totalAvailable');
      await _loadData();
    } on TelegramBotApiException catch (error) {
      Toastr.error(error.message);
    } catch (_) {
      Toastr.error('Không thể import tồn kho');
    }
  }

  Future<void> _adjustManualStock() async {
    final controller = TextEditingController();

    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều chỉnh manual stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Nhập số tăng/giảm, ví dụ: 5 hoặc -3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (raw == null || raw.isEmpty) {
      return;
    }

    final delta = int.tryParse(raw);
    if (delta == null) {
      Toastr.error('Delta không hợp lệ');
      return;
    }

    try {
      await _api.adjustProductInventory(widget.productId, delta: delta);
      Toastr.success('Đã điều chỉnh tồn kho');
      await _loadData();
    } on TelegramBotApiException catch (error) {
      Toastr.error(error.message);
    } catch (_) {
      Toastr.error('Không thể điều chỉnh tồn kho');
    }
  }

  Future<void> _openOrderDetail(int orderId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelegramBotOrderDetailScreen(token: widget.token, orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sản phẩm #${widget.productId}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Sửa sản phẩm',
            onPressed: product == null ? null : _openEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: _isLoading && product == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && product == null
          ? _ErrorView(message: _error!, onRetry: _loadData)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildInfoCard(product ?? const {}),
                  const SizedBox(height: 12),
                  _buildInventoryCard(),
                  const SizedBox(height: 12),
                  _buildRelatedOrdersCard(),
                ],
              ),
            ),
      floatingActionButton: product == null
          ? null
          : !_isDucViet && _isManual
          ? FloatingActionButton.extended(
              onPressed: _adjustManualStock,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Adjust stock'),
            )
          : !_isDucViet
          ? FloatingActionButton.extended(
              onPressed: _importAutoInventory,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Import inventory'),
            )
          : null,
    );
  }

  Widget _buildInfoCard(JsonMap product) {
    final cs = Theme.of(context).colorScheme;
    final price = _toInt(product['price']);
    final provider = (product['external_provider'] ?? 'LOCAL').toString();
    final externalId = product['external_product_id'];

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${product['id']} • ${product['name'] ?? ''}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Giá: ${CurrencyHelper.formatCurrency(price)}'),
                ),
                Chip(
                  label: Text('Delivery: ${product['delivery_type'] ?? '-'}'),
                ),
                Chip(label: Text('Provider: $provider')),
                if (externalId != null)
                  Chip(label: Text('External ID: $externalId')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Manual stock: ${product['manual_stock'] ?? 0}'),
            Text('Manual reserved: ${product['manual_reserved'] ?? 0}'),
            Text('Sort order: ${product['sort_order'] ?? 0}'),
            if ((product['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Mô tả: ${product['description']}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    final cs = Theme.of(context).colorScheme;

    if (_isDucViet) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Sản phẩm map DUCVIET: tồn kho lấy trực tiếp từ provider, không quản lý inventory nội bộ.',
          ),
        ),
      );
    }

    final summary = _toMap(_inventory['summary']);
    final items = _toList(_inventory['items']);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tồn kho',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DropdownButton<String>(
                  value: _inventoryStatus,
                  items: _inventoryStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.isEmpty ? 'Tất cả' : status),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    _inventoryStatus = value ?? '';
                    _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Available: ${summary['available'] ?? 0} • Reserved: ${summary['reserved'] ?? 0} • Sold: ${summary['sold'] ?? 0}',
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Chưa có item tồn kho')
            else
              ...items.take(30).map((item) {
                final orderId = _toInt(item['order_id']);
                final content = (item['content'] ?? '').toString();
                final status = (item['status'] ?? '').toString();
                final orderCode = (item['order_code'] ?? '').toString();

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    content.isEmpty ? '#${item['id']}' : content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$status${orderCode.isEmpty ? '' : ' • $orderCode'}',
                  ),
                  trailing: orderId > 0
                      ? IconButton(
                          tooltip: 'Mở order #$orderId',
                          color: cs.primary,
                          onPressed: () => _openOrderDetail(orderId),
                          icon: const Icon(Icons.open_in_new_rounded),
                        )
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedOrdersCard() {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn hàng liên quan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_relatedOrders.isEmpty)
              const Text('Chưa có đơn hàng cho sản phẩm này')
            else
              ..._relatedOrders.take(20).map((row) {
                final orderId = _toInt(row['id']);
                final status = (row['status'] ?? '-').toString();
                final code = (row['order_code'] ?? '#$orderId').toString();
                final user = (row['username'] ?? row['telegram_id'] ?? '-')
                    .toString();

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(code),
                  subtitle: Text('Status: $status • User: $user'),
                  trailing: IconButton(
                    tooltip: 'Mở chi tiết đơn',
                    color: cs.primary,
                    onPressed: () => _openOrderDetail(orderId),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  JsonMap _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  List<JsonMap> _toList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Object>()
        .map((item) => _toMap(item))
        .toList(growable: false);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
