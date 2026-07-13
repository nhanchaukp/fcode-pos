import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/financial/financial_transaction_detail_screen.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class FinancialTransactionScreen extends StatefulWidget {
  const FinancialTransactionScreen({super.key});

  @override
  State<FinancialTransactionScreen> createState() =>
      _FinancialTransactionScreenState();
}

class _FinancialTransactionScreenState
    extends State<FinancialTransactionScreen> {
  final FinacialService _service = FinacialService();

  List<FinancialTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;

  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedType;

  final List<String> _transactionTypes = [
    'order_payment',
    'order_renewal',
    'account_renewal',
    'refund',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getFinancialTransaction(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        type: _selectedType,
        page: _currentPage,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _transactions = response.data!.items;
          _totalPages = response.data!.pagination.lastPage;
          _total = response.data!.pagination.total;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Có lỗi xảy ra';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Có lỗi xảy ra: $e';
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _loadTransactions();
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FilterDialog(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        selectedType: _selectedType,
        transactionTypes: _transactionTypes,
      ),
    );

    if (result != null) {
      setState(() {
        _dateFrom = result['dateFrom'] as DateTime?;
        _dateTo = result['dateTo'] as DateTime?;
        _selectedType = result['type'] as String?;
        _currentPage = 1;
      });
      _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _selectedType = null;
      _currentPage = 1;
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFilters =
        _dateFrom != null || _dateTo != null || _selectedType != null;

    return AppScaffold(
      title: 'Giao dịch tài chính',
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Bộ lọc',
          icon: Badge(
            isLabelVisible: hasFilters,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterDialog,
        ),
        if (hasFilters)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Xóa bộ lọc',
            icon: const Icon(Icons.clear),
            onPressed: _clearFilters,
          ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (hasFilters) _buildFilterChips(colorScheme),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tổng: $_total giao dịch',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(child: _buildBody(scrollController)),
          if (_totalPages > 1) _buildPagination(colorScheme),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerHighest.applyOpacity(0.3),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_dateFrom != null)
            Chip(
              label: Text('Từ: ${DateHelper.formatDate(_dateFrom!)}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _dateFrom = null;
                  _currentPage = 1;
                });
                _loadTransactions();
              },
            ),
          if (_dateTo != null)
            Chip(
              label: Text('Đến: ${DateHelper.formatDate(_dateTo!)}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _dateTo = null;
                  _currentPage = 1;
                });
                _loadTransactions();
              },
            ),
          if (_selectedType != null)
            Chip(
              label: Text(_getTypeLabel(_selectedType!)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedType = null;
                  _currentPage = 1;
                });
                _loadTransactions();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có giao dịch',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildDismissibleTransactionTile(transaction);
      },
    );
  }

  Future<void> _deleteTransaction(FinancialTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa giao dịch "${transaction.transactionId}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _service.deleteFinancialTransaction(
        transaction.id,
      );

      if (!mounted) return;

      if (response.success) {
        Toastr.success('Đã xóa giao dịch ${transaction.transactionId}');
        _loadTransactions();
      } else {
        Toastr.error(response.message ?? 'Xóa giao dịch thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: $e');
    }
  }

  Widget _buildDismissibleTransactionTile(FinancialTransaction transaction) {
    return Dismissible(
      key: Key('transaction_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _deleteTransaction(transaction);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      child: _buildTransactionTile(transaction),
    );
  }

  Future<void> _openTransactionDetail(FinancialTransaction transaction) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FinancialTransactionDetailScreen(transactionId: transaction.id),
      ),
    );

    if (changed == true && mounted) {
      _loadTransactions();
    }
  }

  Widget _buildTransactionTile(FinancialTransaction transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.category == 'revenue';
    final amountColor = isIncome ? Colors.green : Colors.red;
    final status = FinancialTransactionStatus.fromValue(transaction.status);

    return InkWell(
      onTap: () => _openTransactionDetail(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.transactionId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      EnumBadge(
                        value: status,
                        fallbackLabel: transaction.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(transaction.type),
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _getTypeLabel(transaction.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: _getCategoryLabel(transaction.category),
                        color: amountColor,
                      ),
                    ],
                  ),
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (transaction.completedAt != null) ...[
                        Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            DateHelper.formatDateTime(transaction.completedAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      Text(
                        CurrencyHelper.formatCurrency(
                          transaction.amount.toInt(),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text(
            'Trang $_currentPage/$_totalPages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: _currentPage > 1
                ? () => _onPageChanged(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _currentPage < _totalPages
                ? () => _onPageChanged(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order_payment':
        return Icons.shopping_cart_outlined;
      case 'order_renewal':
        return Icons.autorenew_outlined;
      case 'account_renewal':
        return Icons.vpn_key_outlined;
      case 'refund':
        return Icons.replay_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'order_payment':
        return 'Thanh toán đơn hàng';
      case 'order_renewal':
        return 'Gia hạn đơn hàng';
      case 'account_renewal':
        return 'Gia hạn tài khoản';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'revenue':
        return 'Thu';
      case 'expense':
        return 'Chi';
      case 'cost':
        return 'Giá vốn';
      case 'refund':
        return 'Hoàn';
      default:
        return category;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedType;
  final List<String> transactionTypes;

  const _FilterDialog({
    this.dateFrom,
    this.dateTo,
    this.selectedType,
    required this.transactionTypes,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _selectedType = widget.selectedType;
  }

  Future<void> _selectDateFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateFrom = date);
    }
  }

  Future<void> _selectDateTo() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateTo = date);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'order_payment':
        return 'Thanh toán đơn hàng';
      case 'order_renewal':
        return 'Gia hạn đơn hàng';
      case 'account_renewal':
        return 'Gia hạn tài khoản';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lọc giao dịch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date From
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Từ ngày'),
              subtitle: Text(
                _dateFrom != null
                    ? DateHelper.formatDate(_dateFrom!)
                    : 'Chọn ngày',
              ),
              onTap: _selectDateFrom,
              trailing: _dateFrom != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dateFrom = null),
                    )
                  : null,
            ),

            // Date To
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Đến ngày'),
              subtitle: Text(
                _dateTo != null ? DateHelper.formatDate(_dateTo!) : 'Chọn ngày',
              ),
              onTap: _selectDateTo,
              trailing: _dateTo != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dateTo = null),
                    )
                  : null,
            ),

            const SizedBox(height: 16),
            const Text(
              'Loại giao dịch',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Transaction Types
            ...widget.transactionTypes.map(
              (type) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(_getTypeLabel(type)),
                value: type,
                groupValue: _selectedType,
                onChanged: (value) => setState(() => _selectedType = value),
              ),
            ),
            if (_selectedType != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedType = null),
                icon: const Icon(Icons.clear),
                label: const Text('Xóa bộ lọc loại'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'dateFrom': _dateFrom,
              'dateTo': _dateTo,
              'type': _selectedType,
            });
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }
}
