import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/account_expense_create_data.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_category_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/financial_transaction_type_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class AccountMasterBatchExpenseCreateScreen extends StatefulWidget {
  const AccountMasterBatchExpenseCreateScreen({
    required this.selectedAccounts,
    super.key,
  });

  final List<AccountMaster> selectedAccounts;

  @override
  State<AccountMasterBatchExpenseCreateScreen> createState() =>
      _AccountMasterBatchExpenseCreateScreenState();
}

class _AccountExpenseItemData {
  final AccountMaster account;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  bool isIncluded = true;

  _AccountExpenseItemData({
    required this.account,
    required this.amountController,
    required this.descriptionController,
  });

  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
  }
}

class _AccountMasterBatchExpenseCreateScreenState
    extends State<AccountMasterBatchExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  enums.FinancialTransactionType _selectedType =
      enums.FinancialTransactionType.accountRenewal;
  enums.FinancialTransactionCategory _selectedCategory =
      enums.FinancialTransactionCategory.expense;
  DateTime _selectedDate = DateTime.now();

  late List<_AccountExpenseItemData> _items;
  bool _isSubmitting = false;
  int _currentIndex = 0;
  int _totalToProcess = 0;
  String _currentProcessingUsername = '';

  @override
  void initState() {
    super.initState();
    _items = widget.selectedAccounts.map((account) {
      final defaultAmount = account.monthlyCost ?? 0;
      final defaultDesc =
          'Chi phí hàng tháng cho tài khoản ${account.serviceType} - ${account.username}';
      return _AccountExpenseItemData(
        account: account,
        amountController: TextEditingController(
          text: defaultAmount > 0 ? defaultAmount.toString() : '',
        ),
        descriptionController: TextEditingController(text: defaultDesc),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _totalAmount {
    int sum = 0;
    for (final item in _items) {
      if (item.isIncluded) {
        sum += item.amountController.moneyValue;
      }
    }
    return sum;
  }

  int get _includedCount => _items.where((i) => i.isIncluded).length;

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

  void _selectAll(bool select) {
    setState(() {
      for (final item in _items) {
        item.isIncluded = select;
      }
    });
  }

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate()) {
      Toastr.error('Vui lòng kiểm tra lại thông tin nhập liệu');
      return;
    }

    final activeItems = _items.where((i) => i.isIncluded).toList();
    if (activeItems.isEmpty) {
      Toastr.warning('Vui lòng chọn ít nhất 1 tài khoản để tạo chi phí');
      return;
    }

    for (final item in activeItems) {
      final amt = item.amountController.moneyValue;
      if (amt <= 0) {
        Toastr.error(
          'Tài khoản ${item.account.username} có số tiền chi phí không hợp lệ',
        );
        return;
      }
      if (item.descriptionController.text.trim().isEmpty) {
        Toastr.error('Tài khoản ${item.account.username} chưa có mô tả');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _currentIndex = 0;
      _totalToProcess = activeItems.length;
    });

    final service = AccountMasterService();
    int successCount = 0;
    int failCount = 0;
    final List<String> errors = [];

    for (int i = 0; i < activeItems.length; i++) {
      final item = activeItems[i];
      if (!mounted) break;

      setState(() {
        _currentIndex = i + 1;
        _currentProcessingUsername = item.account.username;
      });

      try {
        final data = AccountExpenseCreateData(
          accountId: item.account.id,
          type: _selectedType,
          category: _selectedCategory,
          amount: item.amountController.moneyValue,
          description: item.descriptionController.text.trim(),
          expenseDate: _selectedDate,
        );
        await service.createExpense(data);
        successCount++;
      } catch (e) {
        failCount++;
        errors.add('${item.account.username}: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (failCount == 0) {
      Toastr.success(
        'Tạo thành công $successCount chi phí hàng loạt',
        context: context,
      );
      Navigator.pop(context, true);
    } else if (successCount > 0) {
      Toastr.warning(
        'Tạo thành công $successCount, thất bại $failCount chi phí',
        context: context,
      );
      Navigator.pop(context, true);
    } else {
      Toastr.error(
        'Tạo chi phí thất bại: ${errors.join(', ')}',
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo chi phí hàng loạt (${_items.length})'),
        actions: [
          IconButton(
            tooltip: 'Chọn tất cả',
            icon: const Icon(Icons.select_all),
            onPressed: _isSubmitting ? null : () => _selectAll(true),
          ),
          IconButton(
            tooltip: 'Bỏ chọn tất cả',
            icon: const Icon(Icons.deselect),
            onPressed: _isSubmitting ? null : () => _selectAll(false),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isSubmitting)
              Container(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đang xử lý $_currentIndex / $_totalToProcess...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tài khoản: $_currentProcessingUsername',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Shared Settings Section
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                size: 20,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cấu hình chi phí chung',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FinancialTransactionTypeDropdown(
                            initialValue: _selectedType,
                            required: true,
                            onChanged: (v) {
                              if (!_isSubmitting && v != null) {
                                setState(() => _selectedType = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          FinancialTransactionCategoryDropdown(
                            initialValue: _selectedCategory,
                            required: true,
                            onChanged: (v) {
                              if (!_isSubmitting && v != null) {
                                setState(() => _selectedCategory = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _isSubmitting ? null : _pickDateTime,
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
                                _selectedDate
                                    .toLocal()
                                    .toString()
                                    .substring(0, 19),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Accounts list header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách tài khoản ($_includedCount / ${_items.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tổng: ${CurrencyHelper.formatCurrency(_totalAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Accounts list items
                  ..._items.map((item) {
                    final account = item.account;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: item.isIncluded
                          ? cs.surface
                          : cs.surfaceContainerLowest.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: item.isIncluded
                              ? cs.outlineVariant
                              : cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: item.isIncluded,
                                  onChanged: _isSubmitting
                                      ? null
                                      : (val) {
                                          setState(() {
                                            item.isIncluded = val ?? false;
                                          });
                                        },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    account.serviceType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    account.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: item.isIncluded
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (account.monthlyCost != null)
                                  Text(
                                    'Định phí: ${CurrencyHelper.formatCurrency(account.monthlyCost!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            if (item.isIncluded) ...[
                              const Divider(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: MoneyFormField(
                                      controller: item.amountController,
                                      labelText: 'Chi phí *',
                                      enabled: !_isSubmitting,
                                      onChanged: (_) {
                                        setState(() {});
                                      },
                                      validator: (value) {
                                        if (!item.isIncluded) return null;
                                        if (item
                                                .amountController
                                                .moneyValue <=
                                            0) {
                                          return 'Hợp lệ > 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: item.descriptionController,
                                      enabled: !_isSubmitting,
                                      decoration: InputDecoration(
                                        labelText: 'Mô tả *',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (!item.isIncluded) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Nhập mô tả';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng chi phí ($_includedCount TK):',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatCurrency(_totalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitting || _includedCount == 0
                      ? null
                      : _submitBatch,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_card),
                  label: Text(
                    _isSubmitting
                        ? 'Đang tạo ($_currentIndex/$_totalToProcess)...'
                        : 'Tạo $_includedCount chi phí',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
