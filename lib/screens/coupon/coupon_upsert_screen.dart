import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/coupon_service.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CouponUpsertScreen extends StatefulWidget {
  const CouponUpsertScreen({super.key, this.couponId});

  final int? couponId;

  bool get isEditing => couponId != null;

  @override
  State<CouponUpsertScreen> createState() => _CouponUpsertScreenState();
}

class _CouponUpsertScreenState extends State<CouponUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _couponService = CouponService();

  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController();
  final _limitController = TextEditingController();
  final _maxDiscountController = TextEditingController();

  CouponType _type = CouponType.subtraction;
  DateTime? _expiresAt;
  bool _isEnabled = true;
  bool _isLoading = false;
  bool _isPrefillLoading = false;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadCouponDetail();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    _limitController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _loadCouponDetail() async {
    setState(() => _isPrefillLoading = true);
    try {
      final response = await _couponService.detail(widget.couponId!);
      if (!mounted) return;
      final coupon = response.data;
      if (coupon == null) {
        Toastr.error('Không tìm thấy mã giảm giá');
        Navigator.of(context).pop(false);
        return;
      }
      _prefill(coupon);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Không tải được thông tin: $e');
    } finally {
      if (mounted) setState(() => _isPrefillLoading = false);
    }
  }

  void _prefill(Coupon c) {
    _codeController.text = c.code;
    _valueController.text = c.value;
    _type = c.couponType ?? CouponType.subtraction;
    _isEnabled = c.isEnabled;
    _expiresAt = c.expiresAt;
    _quantityController.text = c.quantity?.toString() ?? '';
    _limitController.text = c.limit?.toString() ?? '';
    _maxDiscountController.text = c.maxDiscount?.toString() ?? '';
    setState(() {});
  }

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date != null && mounted) {
      setState(() => _expiresAt = date);
    }
  }

  Future<void> _submit() async {
    setState(() => _errorBanner = null);
    if (!_formKey.currentState!.validate()) return;
    if (_expiresAt == null) {
      setState(() => _errorBanner = 'Vui lòng chọn ngày hết hạn');
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'code': _codeController.text.trim(),
      'type': _type.value,
      'value': _type == CouponType.percentage
          ? num.tryParse(_valueController.text.trim()) ?? 0
          : CurrencyHelper.parseCurrency(_valueController.text),
      'is_enabled': _isEnabled,
      'expires_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(_expiresAt!),
    };

    final qty = int.tryParse(_quantityController.text.trim());
    if (qty != null) data['quantity'] = qty;

    final limit = int.tryParse(_limitController.text.trim());
    if (limit != null) data['limit'] = limit;

    if (_type == CouponType.percentage) {
      final maxDiscount =
          CurrencyHelper.parseCurrency(_maxDiscountController.text);
      data['data'] = {'maxDiscount': maxDiscount};
    }

    try {
      if (widget.isEditing) {
        await _couponService.update(widget.couponId!, data);
      } else {
        await _couponService.create(data);
      }

      if (!mounted) return;
      Toastr.success(
        widget.isEditing ? 'Đã cập nhật mã giảm giá' : 'Đã tạo mã giảm giá',
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = 'Đã xảy ra lỗi. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa mã giảm giá' : 'Tạo mã giảm giá'),
      ),
      body: _isPrefillLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (_errorBanner != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorBanner!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildSection(
                    icon: Icons.info_outline,
                    title: 'Thông tin cơ bản',
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Mã giảm giá'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CouponType>(
                        initialValue: _type,
                        decoration: const InputDecoration(labelText: 'Loại'),
                        items: CouponType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_type == CouponType.percentage)
                        TextFormField(
                          controller: _valueController,
                          decoration: const InputDecoration(
                            labelText: 'Giá trị (%)',
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                            final n = num.tryParse(v.trim());
                            if (n == null || n <= 0 || n > 100) {
                              return 'Từ 1 đến 100';
                            }
                            return null;
                          },
                        )
                      else
                        MoneyFormField(
                          controller: _valueController,
                          labelText: 'Giá trị (VND)',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                        ),
                      if (_type == CouponType.percentage) ...[
                        const SizedBox(height: 12),
                        MoneyFormField(
                          controller: _maxDiscountController,
                          labelText: 'Giảm tối đa (VND)',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.tune,
                    title: 'Giới hạn',
                    children: [
                      InkWell(
                        onTap: _pickExpiresAt,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày hết hạn',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _expiresAt != null
                                ? DateHelper.formatDate(_expiresAt)
                                : 'Chọn ngày',
                            style: TextStyle(
                              color: _expiresAt != null
                                  ? null
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng (tùy chọn)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _limitController,
                        decoration: const InputDecoration(
                          labelText: 'Giới hạn mỗi user (tùy chọn)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kích hoạt'),
                        value: _isEnabled,
                        onChanged: (v) => setState(() => _isEnabled = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: LoadingIcon(
                      loading: _isLoading,
                      icon: Icons.check,
                    ),
                    label: Text(widget.isEditing ? 'Cập nhật' : 'Tạo mới'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
