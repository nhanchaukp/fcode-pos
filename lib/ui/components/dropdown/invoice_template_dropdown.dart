import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/invoice_service.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:flutter/material.dart';

String _invoiceTemplateKey(InvoiceTemplate t) =>
    '${t.templateCode}|${t.invoiceSeries}';

/// Chọn `[template_code, invoice_series]` từ chi tiết tài khoản NCC
/// (`GET …/provider-accounts/{id}`). Label là [InvoiceTemplate.invoiceLabel].
class InvoiceTemplateDropdown extends StatefulWidget {
  const InvoiceTemplateDropdown({
    super.key,
    required this.providerAccountId,
    this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelText,
  });

  final String? providerAccountId;
  final InvoiceTemplate? value;
  final ValueChanged<InvoiceTemplate?> onChanged;

  final FormFieldValidator<InvoiceTemplate?>? validator;

  final bool enabled;
  final String? labelText;

  @override
  State<InvoiceTemplateDropdown> createState() =>
      _InvoiceTemplateDropdownState();
}

class _InvoiceTemplateDropdownState extends State<InvoiceTemplateDropdown> {
  final _service = InvoiceService();
  final _textController = TextEditingController();
  List<InvoiceTemplate> _templates = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _textController.text = widget.value!.invoiceLabel;
    }
    _syncLoad();
  }

  @override
  void didUpdateWidget(covariant InvoiceTemplateDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerAccountId != widget.providerAccountId) {
      _templates = [];
      _error = null;
      _textController.clear();
      widget.onChanged(null);
      _syncLoad();
    }
    if (widget.value != oldWidget.value) {
      _textController.text = widget.value?.invoiceLabel ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _syncLoad() async {
    final id = widget.providerAccountId?.trim();
    if (id == null || id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getProvider(id);
      if (!mounted) return;
      final list = res.data?.templates ?? [];
      setState(() {
        _templates = list;
        _loading = false;
      });

      final v = widget.value;
      if (v != null &&
          !_templates.any(
            (t) => _invoiceTemplateKey(t) == _invoiceTemplateKey(v),
          )) {
        widget.onChanged(null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _templates = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText ?? 'Mẫu hóa đơn';
    final id = widget.providerAccountId?.trim();

    if (id == null || id.isEmpty) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Chọn tài khoản NCC trước',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        ),
      );
    }

    if (_loading && _templates.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          suffixIcon: const SizedBox(
            width: 22,
            height: 22,
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

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không tải mẫu: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: _syncLoad,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }

    if (_templates.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          helperText: 'Không có mẫu cho tài khoản này',
        ),
        child: const Text('—'),
      );
    }

    return TextFormField(
      controller: _textController,
      readOnly: true,
      enabled: widget.enabled && _templates.isNotEmpty,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: _templates.isEmpty ? 'Không có mẫu khả dụng' : 'Chọn mẫu',
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
      onTap: (widget.enabled && _templates.isNotEmpty) ? _openPickerSheet : null,
      validator: (_) {
        if (widget.validator != null) return widget.validator!(widget.value);
        if (widget.value == null) return 'Chọn mẫu hóa đơn';
        return null;
      },
    );
  }

  Future<void> _openPickerSheet() async {
    final selected = await showModalBottomSheet<InvoiceTemplate>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TemplateSelectSheet(
        templates: _templates,
        selected: widget.value,
      ),
    );
    if (selected == null) return;
    _textController.text = selected.invoiceLabel;
    widget.onChanged(selected);
  }
}

class _TemplateSelectSheet extends StatefulWidget {
  const _TemplateSelectSheet({
    required this.templates,
    this.selected,
  });

  final List<InvoiceTemplate> templates;
  final InvoiceTemplate? selected;

  @override
  State<_TemplateSelectSheet> createState() => _TemplateSelectSheetState();
}

class _TemplateSelectSheetState extends State<_TemplateSelectSheet> {
  late final TextEditingController _searchCtrl;
  late List<InvoiceTemplate> _filtered;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filtered = widget.templates;
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
                hintText: 'Tìm mẫu hóa đơn...',
                onChanged: (query) {
                  final q = query.trim().toLowerCase();
                  if (!mounted) return;
                  setState(() {
                    _filtered = widget.templates.where((e) {
                      final text =
                          '${e.invoiceLabel} ${e.templateCode} ${e.invoiceSeries}'
                              .toLowerCase();
                      return text.contains(q);
                    }).toList(growable: false);
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('Không có mẫu phù hợp'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final selected = widget.selected != null &&
                              _invoiceTemplateKey(item) ==
                                  _invoiceTemplateKey(widget.selected!);
                          return ListTile(
                            title: Text(
                              item.invoiceLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Mẫu ${item.templateCode} · Series ${item.invoiceSeries}',
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
