import 'dart:convert';

import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotProductEditScreen extends StatefulWidget {
  const TelegramBotProductEditScreen({
    super.key,
    required this.token,
    this.product,
  });

  final String token;
  final JsonMap? product;

  bool get isEditing => product != null;

  @override
  State<TelegramBotProductEditScreen> createState() =>
      _TelegramBotProductEditScreenState();
}

class _TelegramBotProductEditScreenState
    extends State<TelegramBotProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TelegramBotApiClient _api;

  late final TextEditingController _parentIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _manualStockController;
  late final TextEditingController _manualFieldsController;
  late final TextEditingController _sortOrderController;

  bool _active = true;
  bool _requireAccount = false;
  bool _requirePassword = false;
  String _deliveryType = 'AUTO';
  String _externalProvider = 'LOCAL';
  int? _selectedExternalProductId;

  bool _isSubmitting = false;
  bool _isLoadingDucViet = false;
  List<JsonMap> _ducVietProducts = const [];

  bool get _isDucViet => _externalProvider == 'DUCVIET';

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);

    final row = widget.product;
    _parentIdController = TextEditingController(
      text: row?['parent_id']?.toString() ?? '',
    );
    _nameController = TextEditingController(
      text: row?['name']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: row?['description']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: (row?['price'] ?? 0).toString(),
    );
    _manualStockController = TextEditingController(
      text: (row?['manual_stock'] ?? 0).toString(),
    );
    _manualFieldsController = TextEditingController(
      text: row?['manual_fields_json']?.toString() ?? '',
    );
    _sortOrderController = TextEditingController(
      text: (row?['sort_order'] ?? 0).toString(),
    );

    _active = _toInt(row?['active'], fallback: 1) == 1;
    _requireAccount = _toInt(row?['require_account']) == 1;
    _requirePassword = _toInt(row?['require_password']) == 1;
    _deliveryType =
        (row?['delivery_type'] ?? 'AUTO').toString().toUpperCase() == 'MANUAL'
        ? 'MANUAL'
        : 'AUTO';
    _externalProvider =
        (row?['external_provider'] ?? 'LOCAL').toString().toUpperCase() ==
            'DUCVIET'
        ? 'DUCVIET'
        : 'LOCAL';

    final externalId = row?['external_product_id'];
    if (externalId != null) {
      _selectedExternalProductId = _toInt(externalId);
    }

    if (_isDucViet) {
      _deliveryType = 'AUTO';
      _loadDucVietProducts();
    }
  }

  @override
  void dispose() {
    _parentIdController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _manualStockController.dispose();
    _manualFieldsController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadDucVietProducts({bool refresh = false}) async {
    setState(() => _isLoadingDucViet = true);

    try {
      final rows = await _api.getDucVietProducts(refresh: refresh);
      if (!mounted) {
        return;
      }

      setState(() {
        _ducVietProducts = rows;
      });
    } on TelegramBotApiException catch (error) {
      Toastr.error(error.message);
    } catch (_) {
      Toastr.error('Không thể tải dữ liệu DucVietStore');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDucViet = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isDucViet && _selectedExternalProductId == null) {
      Toastr.warning('Vui lòng chọn sản phẩm DucVietStore để map');
      return;
    }

    dynamic manualFieldsJson;
    final rawManualFields = _manualFieldsController.text.trim();
    if (rawManualFields.isNotEmpty) {
      try {
        manualFieldsJson = jsonDecode(rawManualFields);
      } catch (_) {
        Toastr.error('manual_fields_json phải là JSON hợp lệ');
        return;
      }
    }

    final payload = <String, dynamic>{
      'parent_id': _parentIdController.text.trim().isEmpty
          ? null
          : int.tryParse(_parentIdController.text.trim()),
      'active': _active ? 1 : 0,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'delivery_type': _isDucViet ? 'AUTO' : _deliveryType,
      'price': _toInt(_priceController.text, fallback: 0),
      'manual_stock': _toInt(_manualStockController.text, fallback: 0),
      'manual_fields_json': manualFieldsJson,
      'require_account': _requireAccount ? 1 : 0,
      'require_password': _requirePassword ? 1 : 0,
      'sort_order': _toInt(_sortOrderController.text, fallback: 0),
      'external_provider': _externalProvider,
      'external_product_id': _isDucViet ? _selectedExternalProductId : null,
    };

    if (payload['parent_id'] == null &&
        _parentIdController.text.trim().isNotEmpty) {
      Toastr.error('parent_id không hợp lệ');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        final id = _toInt(widget.product?['id']);
        if (id <= 0) {
          throw TelegramBotApiException('Thiếu product id để cập nhật');
        }
        await _api.updateProduct(id, payload);
        Toastr.success('Đã cập nhật sản phẩm');
      } else {
        await _api.createProduct(payload);
        Toastr.success('Đã tạo sản phẩm mới');
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on TelegramBotApiException catch (error) {
      Toastr.error(error.message);
    } catch (_) {
      Toastr.error('Không thể lưu sản phẩm');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _buildHeaderCard(cs),
            const SizedBox(height: 12),
            _buildBasicInfoSection(cs),
            const SizedBox(height: 12),
            _buildProviderSection(cs),
            const SizedBox(height: 12),
            _buildAdvancedSection(cs),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu sản phẩm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary,
            child: Icon(
              widget.isEditing ? Icons.edit_rounded : Icons.add_box_rounded,
              color: cs.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isEditing
                  ? 'Cập nhật thông tin sản phẩm và mapping provider'
                  : 'Tạo sản phẩm mới cho Telegram Bot',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(ColorScheme cs) {
    return _buildSectionCard(
      cs,
      title: 'Thông tin cơ bản',
      children: [
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Tên sản phẩm là bắt buộc';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descriptionController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Mô tả'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá (VND)'),
                validator: (value) {
                  if (int.tryParse((value ?? '').trim()) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sort order'),
                validator: (value) {
                  if (int.tryParse((value ?? '').trim()) == null) {
                    return 'Sort order không hợp lệ';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderSection(ColorScheme cs) {
    return _buildSectionCard(
      cs,
      title: 'Giao hàng & nhà cung cấp',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _parentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Parent ID (tuỳ chọn)',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _manualStockController,
                keyboardType: TextInputType.number,
                enabled: !_isDucViet,
                decoration: const InputDecoration(labelText: 'Manual stock'),
                validator: (value) {
                  if (int.tryParse((value ?? '').trim()) == null) {
                    return 'Stock không hợp lệ';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _externalProvider,
          decoration: const InputDecoration(labelText: 'External provider'),
          items: const [
            DropdownMenuItem(value: 'LOCAL', child: Text('LOCAL')),
            DropdownMenuItem(value: 'DUCVIET', child: Text('DUCVIET')),
          ],
          onChanged: (value) {
            final next = value ?? 'LOCAL';
            setState(() {
              _externalProvider = next;
              if (_isDucViet) {
                _deliveryType = 'AUTO';
              } else {
                _selectedExternalProductId = null;
              }
            });

            if (_isDucViet && _ducVietProducts.isEmpty) {
              _loadDucVietProducts();
            }
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _deliveryType,
          decoration: const InputDecoration(labelText: 'Delivery type'),
          items: const [
            DropdownMenuItem(value: 'AUTO', child: Text('AUTO')),
            DropdownMenuItem(value: 'MANUAL', child: Text('MANUAL')),
          ],
          onChanged: _isDucViet
              ? null
              : (value) {
                  setState(() => _deliveryType = value ?? 'AUTO');
                },
        ),
        if (_isDucViet) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Provider DUCVIET sẽ luôn dùng AUTO và yêu cầu map external_product_id.',
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedExternalProductId,
                  decoration: const InputDecoration(
                    labelText: 'Map tới sản phẩm DucVietStore',
                  ),
                  items: _buildDucVietProductItems(),
                  onChanged: _isLoadingDucViet
                      ? null
                      : (value) {
                          setState(() => _selectedExternalProductId = value);
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh sản phẩm DucVietStore',
                onPressed: _isLoadingDucViet
                    ? null
                    : () => _loadDucVietProducts(refresh: true),
                icon: _isLoadingDucViet
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection(ColorScheme cs) {
    return _buildSectionCard(
      cs,
      title: 'Tuỳ chọn nâng cao',
      children: [
        TextFormField(
          controller: _manualFieldsController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'manual_fields_json (tuỳ chọn)',
            hintText: '[{"key":"server","label":"Server","required":true}]',
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _active,
          onChanged: (value) => setState(() => _active = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
        ),
        SwitchListTile.adaptive(
          value: _requireAccount,
          onChanged: (value) => setState(() => _requireAccount = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Yêu cầu account'),
        ),
        SwitchListTile.adaptive(
          value: _requirePassword,
          onChanged: (value) => setState(() => _requirePassword = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Yêu cầu password'),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    ColorScheme cs, {
    required String title,
    required List<Widget> children,
  }) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildDucVietProductItems() {
    final items = <DropdownMenuItem<int>>[];

    final current = _selectedExternalProductId;
    final mappedIds = _ducVietProducts
        .map((row) => _asIntOrNull(row['id']))
        .whereType<int>()
        .toSet();

    if (current != null && !mappedIds.contains(current)) {
      items.add(
        DropdownMenuItem<int>(
          value: current,
          child: Text('#$current - Mapping hiện tại'),
        ),
      );
    }

    for (final row in _ducVietProducts) {
      final providerId = _asIntOrNull(row['id']);
      if (providerId == null) {
        continue;
      }

      items.add(
        DropdownMenuItem<int>(
          value: providerId,
          child: Text(
            '#$providerId - ${row['name']} (Tồn: ${row['availableStock'] ?? 0})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return items;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    return _asIntOrNull(value) ?? fallback;
  }

  int? _asIntOrNull(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
