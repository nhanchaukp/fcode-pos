import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:flutter/material.dart';

String _invoiceProviderDisplayLabel(String code) =>
    switch (code.toLowerCase()) {
      'matbao' => 'Mắt Bảo',
      _ => code.isEmpty ? '—' : code,
    };

/// Chọn `provider_account_id` từ [InvoiceService.listProviders].
class InvoiceProviderAccountDropdown extends StatefulWidget {
  const InvoiceProviderAccountDropdown({
    super.key,
    this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelText,
  });

  final InvoiceProviderAccount? value;
  final ValueChanged<InvoiceProviderAccount?> onChanged;

  /// Trả `null` nếu bắt buộc mà chưa chọn.
  final FormFieldValidator<InvoiceProviderAccount>? validator;

  final bool enabled;
  final String? labelText;

  @override
  State<InvoiceProviderAccountDropdown> createState() =>
      _InvoiceProviderAccountDropdownState();
}

class _InvoiceProviderAccountDropdownState
    extends State<InvoiceProviderAccountDropdown> {
  final _service = InvoiceService();
  final _textController = TextEditingController();
  List<InvoiceProviderAccount> _items = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _textController.text = _label(widget.value!);
    }
    _load();
  }

  @override
  void didUpdateWidget(covariant InvoiceProviderAccountDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.id != oldWidget.value?.id) {
      _textController.text = widget.value != null ? _label(widget.value!) : '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await _service.listProviders(page: 1, perPage: 100);
      if (!mounted) return;
      setState(() {
        _items = res.data?.items ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _items = [];
        _loading = false;
      });
    }
  }

  String _label(InvoiceProviderAccount a) =>
      '${_invoiceProviderDisplayLabel(a.provider)} · ${a.id.length > 12 ? '${a.id.substring(0, 8)}…' : a.id}';

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText ?? 'Tài khoản nhà cung cấp';

    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          suffixIcon: const SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        child: const SizedBox(height: 24),
      );
    }

    if (_loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không tải được danh sách NCC',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          helperText: 'Chưa có tài khoản nhà cung cấp hoạt động',
        ),
        child: Text(
          '—',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return TextFormField(
      controller: _textController,
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: 'Chọn tài khoản',
        suffixIcon: widget.value != null && widget.enabled
            ? IconButton(
                onPressed: () {
                  _textController.clear();
                  widget.onChanged(null);
                },
                icon: const Icon(Icons.clear),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: widget.enabled ? _openPickerSheet : null,
      validator: (_) => widget.validator?.call(_coerceValue(widget.value)),
    );
  }

  Future<void> _openPickerSheet() async {
    final selected = await showModalBottomSheet<InvoiceProviderAccount>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ProviderSelectSheet(
        items: _items,
        selected: _coerceValue(widget.value),
        labelBuilder: _label,
      ),
    );
    if (selected == null) return;
    _textController.text = _label(selected);
    widget.onChanged(selected);
  }

  /// Giữ value hợp lệ nếu object mới load khác instance.
  InvoiceProviderAccount? _coerceValue(InvoiceProviderAccount? v) {
    if (v == null) return null;
    try {
      return _items.firstWhere((e) => e.id == v.id);
    } catch (_) {
      return null;
    }
  }
}

class _ProviderSelectSheet extends StatefulWidget {
  const _ProviderSelectSheet({
    required this.items,
    required this.labelBuilder,
    this.selected,
  });

  final List<InvoiceProviderAccount> items;
  final InvoiceProviderAccount? selected;
  final String Function(InvoiceProviderAccount) labelBuilder;

  @override
  State<_ProviderSelectSheet> createState() => _ProviderSelectSheetState();
}

class _ProviderSelectSheetState extends State<_ProviderSelectSheet> {
  late final TextEditingController _searchCtrl;
  late List<InvoiceProviderAccount> _filtered;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              DebouncedSearchInput(
                controller: _searchCtrl,
                autofocus: true,
                hintText: 'Tìm tài khoản nhà cung cấp...',
                onChanged: (query) {
                  final q = query.trim().toLowerCase();
                  if (!mounted) return;
                  setState(() {
                    _filtered = widget.items.where((e) {
                      final text = widget.labelBuilder(e).toLowerCase();
                      return text.contains(q);
                    }).toList(growable: false);
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('Không có dữ liệu phù hợp'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final selected = widget.selected?.id == item.id;
                          return ListTile(
                            title: Text(
                              _invoiceProviderDisplayLabel(item.provider),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
