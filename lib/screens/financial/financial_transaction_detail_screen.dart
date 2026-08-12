import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/update_financial_transaction_data.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/app_section_card.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_category_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_status_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_type_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class FinancialTransactionDetailScreen extends StatefulWidget {
  const FinancialTransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.onChanged,
  });

  final int transactionId;

  /// Gọi khi có thay đổi. Tránh chặn pop bằng [PopScope] để iOS vẫn vuốt back được.
  final VoidCallback? onChanged;

  @override
  State<FinancialTransactionDetailScreen> createState() =>
      _FinancialTransactionDetailScreenState();
}

class _FinancialTransactionDetailScreenState
    extends State<FinancialTransactionDetailScreen> {
  final _service = FinacialService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  FinancialTransaction? _transaction;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;
  bool _changed = false;

  void _markChanged() {
    if (_changed) return;
    _changed = true;
    widget.onChanged?.call();
  }

  enums.FinancialTransactionType? _selectedType;
  enums.FinancialTransactionCategory? _selectedCategory;
  enums.FinancialTransactionStatus? _selectedStatus;
  DateTime? _processedAt;
  DateTime? _completedAt;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ColorScheme get _colorScheme => Theme.of(context).colorScheme;

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getFinancialTransactionDetail(
        widget.transactionId,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() => _transaction = response.data);
        _bindForm(response.data!);
      } else {
        setState(() => _error = response.message ?? 'Không tải được giao dịch');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Load financial transaction: $e');
      if (!mounted) return;
      setState(() => _error = 'Không thể tải chi tiết giao dịch.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bindForm(FinancialTransaction transaction) {
    _selectedType = enums.FinancialTransactionType.fromValue(transaction.type);
    _selectedCategory = enums.FinancialTransactionCategory.fromValue(
      transaction.category,
    );
    _selectedStatus = enums.FinancialTransactionStatus.fromValue(
      transaction.status,
    );
    _amountController.text = transaction.amount.round().toString();
    _feeController.text = transaction.fee.round().toString();
    _descriptionController.text = transaction.description ?? '';
    _notesController.text = transaction.notes ?? '';
    _processedAt = transaction.processedAt;
    _completedAt = transaction.completedAt;
  }

  void _startEditing() {
    if (_transaction == null) return;
    _bindForm(_transaction!);
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    if (_transaction != null) _bindForm(_transaction!);
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges() async {
    final transaction = _transaction;
    if (transaction == null || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = _amountController.moneyValue.toDouble();
    final fee = _feeController.moneyValue.toDouble();

    final payload = UpdateFinancialTransactionData(
      type: _selectedType,
      category: _selectedCategory,
      status: _selectedStatus,
      amount: amount,
      fee: fee,
      description: _descriptionController.text,
      notes: _notesController.text,
      processedAt: _processedAt,
      completedAt: _completedAt,
    ).toDirtyPayload(transaction);

    if (payload.isEmpty) {
      Toastr.info('Không có thay đổi nào để lưu');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await _service.updateFinancialTransaction(
        transaction.id,
        payload,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _transaction = response.data;
          _isEditing = false;
        });
        _markChanged();
        _bindForm(response.data!);
        Toastr.success('Cập nhật giao dịch thành công');
      } else {
        Toastr.error(response.message ?? 'Cập nhật thất bại');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      Toastr.error(e.firstFieldError ?? e.message);
    } catch (e, st) {
      debugPrintStack(
        stackTrace: st,
        label: 'Update financial transaction: $e',
      );
      if (!mounted) return;
      Toastr.error('Không thể cập nhật giao dịch');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDateTime({required bool isProcessed}) async {
    final current = isProcessed ? _processedAt : _completedAt;
    final initialDate = current ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isProcessed) {
        _processedAt = picked;
      } else {
        _completedAt = picked;
      }
    });
  }

  void _clearDateTime({required bool isProcessed}) {
    setState(() {
      if (isProcessed) {
        _processedAt = null;
      } else {
        _completedAt = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _transaction?.transactionId ?? 'Chi tiết giao dịch';
    final status = _transaction == null
        ? null
        : enums.FinancialTransactionStatus.fromValue(_transaction!.status);

    return PopScope(
      // Chỉ chặn khi đang lưu; còn lại cho phép vuốt back trên iOS.
      canPop: !_isSaving,
      child: AppScaffold(
        title: title,
        subtitle: status?.label,
        showBack: true,
        onBack: _isSaving ? () {} : null,
        actions: [
          if (_transaction != null && !_isLoading && _error == null) ...[
            if (_isEditing) ...[
              TextButton(
                onPressed: _isSaving ? null : _cancelEditing,
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ] else
              IconButton(
                tooltip: 'Chỉnh sửa',
                visualDensity: VisualDensity.compact,
                onPressed: _startEditing,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ],
        body: (context, scrollController) => _buildBody(scrollController),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: _colorScheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final transaction = _transaction;
    if (transaction == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return RefreshIndicator(
      onRefresh: _isEditing ? () async {} : _loadDetail,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: _isEditing
            ? _buildEditForm(transaction)
            : _buildViewBody(transaction),
      ),
    );
  }

  Widget _buildViewBody(FinancialTransaction transaction) {
    final status = enums.FinancialTransactionStatus.fromValue(
      transaction.status,
    );
    final type = enums.FinancialTransactionType.fromValue(transaction.type);
    final category = enums.FinancialTransactionCategory.fromValue(
      transaction.category,
    );
    final isIncome = transaction.category == 'revenue';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (status != null) EnumBadge(value: status),
              const Spacer(),
              if (type != null) ...[
                EnumBadge(value: type),
                const SizedBox(width: 6),
              ],
              if (category != null) EnumBadge(value: category),
            ],
          ),
          if (transaction.description != null &&
              transaction.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                transaction.description!,
                style: TextStyle(color: _colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Số tiền & Thanh toán',
            icon: Icons.attach_money_outlined,
            children: [
              _amountRow('Số tiền gốc', transaction.amount, isIncome),
              const SizedBox(height: 8),
              _amountRow('Phí', transaction.fee, false, isNegative: true),
              const SizedBox(height: 8),
              Divider(color: _colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              _amountRow(
                'Thực nhận',
                transaction.netAmount,
                isIncome,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Liên kết đối tượng',
            icon: Icons.link_rounded,
            children: [
              _infoRow(
                Icons.link_rounded,
                'Đối tượng',
                _transactionableSummary(transaction),
              ),
              if (_canOpenLinkedOrder(transaction)) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openLinkedOrder(transaction),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Xem đơn hàng'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Thời gian',
            icon: Icons.schedule_outlined,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _compactInfoTile(
                      Icons.schedule_outlined,
                      'Xử lý lúc',
                      DateHelper.formatDateTime(transaction.processedAt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compactInfoTile(
                      Icons.check_circle_outline,
                      'Hoàn thành lúc',
                      DateHelper.formatDateTime(transaction.completedAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _compactInfoTile(
                      Icons.calendar_today_outlined,
                      'Tạo lúc',
                      DateHelper.formatDateTime(transaction.createdAt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compactInfoTile(
                      Icons.update,
                      'Cập nhật lúc',
                      DateHelper.formatDateTime(transaction.updatedAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppSectionCard(
              title: 'Ghi chú',
              icon: Icons.notes_outlined,
              children: [Text(transaction.notes!)],
            ),
          ],
          if (transaction.userId != null || transaction.processedBy != null) ...[
            const SizedBox(height: 12),
            AppSectionCard(
              title: 'Người liên quan',
              icon: Icons.people_outline,
              children: [
                if (transaction.userId != null)
                  _infoRow(
                    Icons.person_outline,
                    'User ID',
                    transaction.userId.toString(),
                  ),
                if (transaction.processedBy != null) ...[
                  if (transaction.userId != null) const SizedBox(height: 8),
                  _infoRow(
                    Icons.admin_panel_settings_outlined,
                    'Xử lý bởi',
                    transaction.processedBy.toString(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm(FinancialTransaction transaction) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionCard(
              title: 'Phân loại giao dịch',
              icon: Icons.category_outlined,
              children: [
                FinancialTransactionTypeDropdown(
                  initialValue: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
                const SizedBox(height: 16),
                FinancialTransactionCategoryDropdown(
                  initialValue: _selectedCategory,
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 16),
                FinancialTransactionStatusDropdown(
                  initialValue: _selectedStatus,
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              title: 'Số tiền & Nội dung',
              icon: Icons.attach_money_outlined,
              children: [
                MoneyFormField(
                  controller: _amountController,
                  labelText: 'Số tiền gốc',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    final parsed = int.tryParse(value.replaceAll('.', '').trim());
                    if (parsed == null || parsed < 0) {
                      return 'Số tiền không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                MoneyFormField(
                  controller: _feeController,
                  labelText: 'Phí',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final parsed = int.tryParse(value.replaceAll('.', '').trim());
                    if (parsed == null || parsed < 0) {
                      return 'Phí không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Net amount sẽ được server tự tính từ amount và fee.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              title: 'Thời gian',
              icon: Icons.schedule_outlined,
              children: [
                _dateTimeField(
                  label: 'Thời gian xử lý',
                  value: _processedAt,
                  onPick: () => _pickDateTime(isProcessed: true),
                  onClear: () => _clearDateTime(isProcessed: true),
                ),
                const SizedBox(height: 12),
                _dateTimeField(
                  label: 'Thời gian hoàn thành',
                  value: _completedAt,
                  onPick: () => _pickDateTime(isProcessed: false),
                  onClear: () => _clearDateTime(isProcessed: false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: Icon(_isSaving ? null : Icons.check),
              label: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Lưu thay đổi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountRow(
    String label,
    double amount,
    bool isIncome, {
    bool isNegative = false,
    bool bold = false,
  }) {
    final color = isNegative
        ? _colorScheme.error
        : (isIncome ? Colors.green.shade700 : Colors.red.shade700);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          CurrencyHelper.formatCurrency(amount.toInt()),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }



  Widget _dateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value != null ? DateHelper.formatDateTime(value) : 'Chưa đặt',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
          IconButton(icon: const Icon(Icons.event_outlined), onPressed: onPick),
        ],
      ),
      onTap: onPick,
    );
  }

  String _morphLabel(String? type) {
    switch (type) {
      case r'App\Models\ShopOrder':
        return 'Đơn hàng';
      case r'App\Models\AccountMaster':
        return 'Tài khoản master';
      case r'App\Models\Refund':
        return 'Hoàn tiền';
      default:
        if (type == null || type.isEmpty) return '-';
        return type.split(r'\').last;
    }
  }

  String _transactionableSummary(FinancialTransaction transaction) {
    final morph = transaction.transactionable;
    final label = _morphLabel(transaction.transactionableType);
    final id = transaction.transactionableId;
    final username = morph?['username']?.toString();
    final code = morph?['code']?.toString();

    if (username != null && username.isNotEmpty) {
      return '$label · $username';
    }
    if (code != null && code.isNotEmpty) {
      return '$label · $code';
    }
    if (id != null) return '$label #$id';
    if (transaction.transactionableType != null) return label;
    return '-';
  }

  bool _canOpenLinkedOrder(FinancialTransaction transaction) {
    return transaction.transactionableType == r'App\Models\ShopOrder' &&
        transaction.transactionableId != null;
  }

  void _openLinkedOrder(FinancialTransaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: transaction.transactionableId.toString(),
        ),
      ),
    );
  }
}
