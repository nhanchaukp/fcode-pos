import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/product_update_data.dart';
import 'package:fcode_pos/services/product_service.dart';
import 'package:fcode_pos/api/api_exception.dart';
import 'package:share_plus/share_plus.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:fcode_pos/ui/components/section_header.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';

class ProductEditScreen extends StatefulWidget {
  final Product product;
  const ProductEditScreen({super.key, required this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();
  bool _isLoading = false;
  String? _error;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _priceSaleController;
  late TextEditingController _instockController;
  late TextEditingController _expiryMonthController;
  late TextEditingController _warningController;
  late TextEditingController _upgradeMethodController;
  bool _isActive = false;
  bool _allowBuyMulti = false;
  bool _requireAccount = false;
  bool _requirePassword = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _priceController = TextEditingController(text: p.price.toString());
    _priceSaleController = TextEditingController(
      text: p.priceSale?.toString() ?? '',
    );
    _instockController = TextEditingController(text: p.instock.toString());
    _expiryMonthController = TextEditingController(
      text: p.expiryMonth?.toString() ?? '',
    );
    _warningController = TextEditingController(text: p.warning ?? '');
    _upgradeMethodController = TextEditingController(
      text: p.upgradeMethod ?? '',
    );
    _isActive = p.isActive;
    _allowBuyMulti = p.allowBuyMulti;
    _requireAccount = p.requireAccount;
    _requirePassword = p.requirePassword;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceSaleController.dispose();
    _instockController.dispose();
    _expiryMonthController.dispose();
    _warningController.dispose();
    _upgradeMethodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = ProductUpdateData(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      price: _priceController.text.trim().isEmpty
          ? null
          : _priceController.moneyValue.toDouble(),
      priceSale: _priceSaleController.text.trim().isEmpty
          ? null
          : _priceSaleController.moneyValue.toDouble(),
      instock: _instockController.text.trim().isEmpty
          ? null
          : int.tryParse(_instockController.text.trim()),
      isActive: _isActive,
      allowBuyMulti: _allowBuyMulti,
      requireAccount: _requireAccount,
      requirePassword: _requirePassword,
      expiryMonth: _expiryMonthController.text.trim().isEmpty
          ? null
          : int.tryParse(_expiryMonthController.text.trim()),
      warning: _warningController.text.trim().isEmpty
          ? null
          : _warningController.text.trim(),
      upgradeMethod: _upgradeMethodController.text.trim().isEmpty
          ? null
          : _upgradeMethodController.text.trim(),
    );
    try {
      await _service.update(data, widget.product.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Cập nhật thất bại.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLink() async {
    final url = '${Environment.baseURL}/${widget.product.slug}';
    try {
      await SharePlus.instance.share(ShareParams(text: url, title: url));
    } catch (e) {
      Toastr.error('Không thể chia sẻ liên kết sản phẩm.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật sản phẩm'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _shareLink,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _Section(
              title: 'Thông tin cơ bản',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm',
                    ),
                    validator: (v) =>
                        v != null && v.length > 255 ? 'Tối đa 255 ký tự' : null,
                  ),
                  const SizedBox(height: 10),
                  MoneyFormField(
                    controller: _priceController,
                    labelText: 'Giá',
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final raw = value.replaceAll('.', '').trim();
                      final parsed = int.tryParse(raw);
                      if (parsed == null || parsed < 0) {
                        return 'Giá phải >= 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  MoneyFormField(
                    controller: _priceSaleController,
                    labelText: 'Giá khuyến mãi',
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final saleRaw = value.replaceAll('.', '').trim();
                      final sale = int.tryParse(saleRaw);
                      if (sale == null || sale < 0) {
                        return 'Giá khuyến mãi phải >= 0';
                      }
                      final price = _priceController.moneyValue;
                      if (price > 0 && sale >= price) {
                        return 'Giá khuyến mãi phải nhỏ hơn giá';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Kho & thời hạn',
              icon: Icons.warehouse_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: QuantityInput(
                      labelText: 'Tồn kho',
                      controller: _instockController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final value = int.tryParse(v);
                        if (value == null || value < 0) {
                          return 'Tồn kho phải >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuantityInput(
                      controller: _expiryMonthController,
                      labelText: 'Tháng sử dụng',
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final value = int.tryParse(v);
                        if (value == null || value < 0) {
                          return 'Hạn sử dụng phải >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Tuỳ chọn',
              icon: Icons.tune_outlined,
              child: Column(
                children: [
                  SwitchListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('Kích hoạt'),
                  ),
                  SwitchListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    value: _allowBuyMulti,
                    onChanged: (v) => setState(() => _allowBuyMulti = v),
                    title: const Text('Cho phép mua nhiều'),
                  ),
                  SwitchListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    value: _requireAccount,
                    onChanged: (v) => setState(() => _requireAccount = v),
                    title: const Text('Yêu cầu tài khoản'),
                  ),
                  SwitchListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    value: _requirePassword,
                    onChanged: (v) => setState(() => _requirePassword = v),
                    title: const Text('Yêu cầu mật khẩu'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Warning (Markdown)',
              icon: Icons.warning_amber_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nội dung cảnh báo hiển thị cho khách hàng (hỗ trợ Markdown).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: MarkdownAutoPreview(
                      controller: _warningController,
                      emojiConvert: true,
                      minLines: 3,
                      toolbarBackground: colorScheme.surfaceContainerHigh,
                      expandableBackground: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Upgrade method',
              icon: Icons.upgrade_outlined,
              child: TextFormField(
                controller: _upgradeMethodController,
                decoration: const InputDecoration(
                  labelText: 'Cách nâng cấp',
                  hintText:
                      'Ví dụ: Đổi email, gia hạn thủ công, upgrade tại web…',
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: LoadingIcon(
                icon: Icons.check_circle_outline_outlined,
                loading: _isLoading,
              ),
              label: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
