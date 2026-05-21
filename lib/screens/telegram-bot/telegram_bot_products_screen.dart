import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_product_detail_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_product_edit_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotProductsScreen extends StatefulWidget {
  const TelegramBotProductsScreen({
    super.key,
    required this.token,
    this.initialSearch,
  });

  final String token;
  final String? initialSearch;

  @override
  State<TelegramBotProductsScreen> createState() =>
      _TelegramBotProductsScreenState();
}

class _TelegramBotProductsScreenState extends State<TelegramBotProductsScreen> {
  final _searchController = TextEditingController();

  late final TelegramBotApiClient _api;
  bool _isLoading = true;
  String? _error;
  List<JsonMap> _products = const [];

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    if ((widget.initialSearch ?? '').trim().isNotEmpty) {
      _searchController.text = widget.initialSearch!.trim();
    }
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getProducts();
      if (!mounted) {
        return;
      }
      setState(() => _products = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải danh sách sản phẩm';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<JsonMap> get _filteredProducts {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _products;
    }

    return _products
        .where((row) {
          final values = [
            row['id'],
            row['name'],
            row['description'],
            row['external_provider'],
            row['external_product_id'],
          ].map((item) => item?.toString().toLowerCase() ?? '');

          return values.any((text) => text.contains(keyword));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredProducts;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot • Sản phẩm'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên / ID / provider',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody(rows)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  Future<void> _createProduct() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TelegramBotProductEditScreen(token: widget.token),
      ),
    );

    if (changed == true) {
      await _loadProducts();
    }
  }

  Future<void> _openProductDetail(JsonMap product) async {
    final productId = _toInt(product['id']);
    if (productId <= 0) {
      Toastr.error('Không tìm thấy product id hợp lệ');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelegramBotProductDetailScreen(
          token: widget.token,
          productId: productId,
          initialProduct: product,
        ),
      ),
    );

    await _loadProducts();
  }

  Future<void> _openEditProduct(JsonMap product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TelegramBotProductEditScreen(token: widget.token, product: product),
      ),
    );

    if (changed == true) {
      await _loadProducts();
    }
  }

  Widget _buildBody(List<JsonMap> rows) {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _loadProducts);
    }

    if (rows.isEmpty) {
      return const Center(child: Text('Không có sản phẩm phù hợp'));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        itemBuilder: (context, index) {
          final row = rows[index];
          final price = (row['price'] as num?)?.toInt() ?? 0;
          final provider = (row['external_provider'] ?? 'LOCAL').toString();
          final externalId = row['external_product_id'];
          final description = (row['description'] ?? '').toString();
          final name = (row['name'] ?? '').toString();

          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: InkWell(
              onTap: () => _openProductDetail(row),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'detail',
                              child: Text('Chi tiết'),
                            ),
                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(
                              value: 'inventory',
                              child: Text('Quản lý tồn kho'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditProduct(row);
                              return;
                            }
                            _openProductDetail(row);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(
                                icon: Icons.tag_rounded,
                                label: '#${row['id'] ?? '-'}',
                              ),
                              _MetaChip(
                                icon: Icons.link_rounded,
                                label: externalId == null
                                    ? provider
                                    : '$provider • $externalId',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyHelper.formatCurrency(price),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: rows.length,
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
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
