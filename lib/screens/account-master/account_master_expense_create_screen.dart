import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_category_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_type_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class AccountMasterExpenseCreateScreen extends StatefulWidget {
  const AccountMasterExpenseCreateScreen({
    required this.accountMaster,
    super.key,
  });

  final AccountMaster accountMaster;

  @override
  State<AccountMasterExpenseCreateScreen> createState() =>
      _AccountMasterExpenseCreateScreenState();
}

class _AccountMasterExpenseCreateScreenState
    extends State<AccountMasterExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  enums.FinancialTransactionType _selectedType =
      enums.FinancialTransactionType.accountRenewal;
  enums.FinancialTransactionCategory _selectedCategory =
      enums.FinancialTransactionCategory.expense;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  int get _defaultAmount {
    final raw = (widget.accountMaster.monthlyCost ?? '0').toString();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController(
      text:
          'Chi phí hàng tháng cho tài khoản ${widget.accountMaster.serviceType} - ${widget.accountMaster.username}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = _amountController.moneyValue;

    if (amount <= 0) {
      Toastr.error('Số tiền phải lớn hơn 0');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = AccountMasterService();
      final data = AccountExpenseCreateData(
        accountId: widget.accountMaster.id,
        type: _selectedType,
        category: _selectedCategory,
        amount: amount,
        description: _descriptionController.text.trim(),
        expenseDate: _selectedDate,
      );
      await service.createExpense(data);
      if (!mounted) return;
      Navigator.pop(context, true);
      Toastr.success('Tạo chi phí thành công');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Toastr.error('Tạo chi phí thất bại: ${e.toString()}');
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) {
      setState(
        () => _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDate.hour,
          _selectedDate.minute,
        ),
      );
      return;
    }
    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tạo chi phí')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin tài khoản',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Dịch vụ',
                        widget.accountMaster.serviceType,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Username', widget.accountMaster.username),
                      if (widget.accountMaster.monthlyCost != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Chi phí hàng tháng',
                          widget.accountMaster.monthlyCost.toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FinancialTransactionTypeDropdown(
                initialValue: _selectedType,
                required: true,
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              FinancialTransactionCategoryDropdown(
                initialValue: _selectedCategory,
                required: true,
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              MoneyFormField(
                controller: _amountController,
                labelText: 'Chi phí *',
                initialValue: _defaultAmount,
                onChanged: (_) {},
                validator: (value) {
                  final amount = _amountController.moneyValue;
                  if (amount <= 0) {
                    return 'Vui lòng nhập số tiền hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Thời gian chi phí *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate.toLocal().toString().substring(0, 19),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập mô tả'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Đang xử lý...' : 'Tạo chi phí'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
