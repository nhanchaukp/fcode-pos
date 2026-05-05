import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/create_order_invoice_data.dart';
import 'package:fcode_pos/screens/order/order_invoice_preview_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/dropdown/invoice_provider_account_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/invoice_template_dropdown.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCreateInvoiceScreen extends StatefulWidget {
  const OrderCreateInvoiceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderCreateInvoiceScreen> createState() =>
      _OrderCreateInvoiceScreenState();
}

class _OrderCreateInvoiceScreenState extends State<OrderCreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _notesCtrl = TextEditingController();

  InvoiceProviderAccount? _account;
  InvoiceTemplate? _template;
  late DateTime _issuedAt;
  TaxRate? _taxRate;
  InvoiceCurrency? _currency;
  InvoicePaymentMethod? _paymentMethod;
  bool _isDraft = true;

  bool _submitting = false;
  bool _loadingPreview = false;

  static final _issuedFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _issuedAt = DateTime.now();
    _previewDefaults();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _previewDefaults() async {
    setState(() => _loadingPreview = true);
    try {
      final res = await _orderService.invoicePreview(widget.orderId);
      if (!mounted) return;
      final p = res.data;
      if (p != null) {
        setState(() {
          _taxRate = p.defaults.taxRate;
          _currency = p.defaults.currency;
          _isDraft = p.defaults.isDraft;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _pickIssuedAt() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_issuedAt),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _issuedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
        _issuedAt.second,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_account == null) {
      Toastr.error('Vui lòng chọn tài khoản nhà cung cấp.');
      return;
    }
    if (_template == null) {
      Toastr.error('Vui lòng chọn mẫu hóa đơn.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _orderService.createInvoice(
        widget.orderId,
        CreateOrderInvoiceData(
          providerAccountId: _account!.id,
          templateCode: _template!.templateCode,
          invoiceSeries: _template!.invoiceSeries,
          issuedDate: _issuedFmt.format(_issuedAt),
          currency: _currency,
          paymentMethod: _paymentMethod,
          isDraft: _isDraft,
          taxRate: _taxRate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      Toastr.success('Đã tạo hóa đơn.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) Toastr.error(e.message);
    } catch (e) {
      if (mounted) Toastr.error('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openPreview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderInvoicePreviewScreen(
          orderId: widget.orderId,
          taxRate: _taxRate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo HĐ đơn ${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Xem preview',
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _loadingPreview ? 3 : 0,
            child: LinearProgressIndicator(
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    InvoiceProviderAccountDropdown(
                      labelText: 'Tài khoản nhà cung cấp',
                      value: _account,
                      onChanged: (a) => setState(() => _account = a),
                      validator: (a) => a == null ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 10),
                    InvoiceTemplateDropdown(
                      key: ValueKey(_account?.id ?? '__none'),
                      providerAccountId: _account?.id,
                      value: _template,
                      labelText: 'Mẫu hóa đơn (template)',
                      onChanged: (t) => setState(() => _template = t),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaxRate?>(
                      initialValue: _taxRate,
                      decoration: const InputDecoration(
                        labelText: 'Thuế suất (TaxRate)',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— Mặc định —'),
                        ),
                        ...TaxRate.values.map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _taxRate = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InvoiceCurrency?>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Tiền tệ (Currency)',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— Mặc định —'),
                        ),
                        ...InvoiceCurrency.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.value} (${c.label})'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _currency = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InvoicePaymentMethod?>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Phương thức thanh toán',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— Mặc định —'),
                        ),
                        ...InvoicePaymentMethod.values.map(
                          (m) =>
                              DropdownMenuItem(value: m, child: Text(m.label)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Ngày giờ phát hành',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      subtitle: Text(_issuedFmt.format(_issuedAt)),
                      trailing: IconButton.filledTonal(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: _pickIssuedAt,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Lưu dưới dạng nháp'),
                      subtitle: Text(
                        _isDraft
                            ? 'Đang gửi is_draft: true'
                            : 'Đang gửi is_draft: false',
                      ),
                      value: _isDraft,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _isDraft = v),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tuỳ chọn)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: LoadingIcon(
                        icon: Icons.receipt_long,
                        loading: _submitting,
                      ),
                      label: const Text('Tạo hóa đơn'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
