import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/account-master/account_master_expense_create_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_upsert_screen.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class AccountMasterDetailScreen extends StatefulWidget {
  final AccountMaster accountMaster;

  const AccountMasterDetailScreen({super.key, required this.accountMaster});

  @override
  State<AccountMasterDetailScreen> createState() =>
      _AccountMasterDetailScreenState();
}

class _AccountMasterDetailScreenState extends State<AccountMasterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AccountMasterService _accountMasterService;

  // Tab 0: Slots
  List<AccountSlot> _slots = [];
  bool _slotsLoading = false;
  String? _slotsError;
  bool _slotsLoaded = false;

  // Tab 1: Transactions
  List<FinancialTransaction> _transactions = [];
  bool _transactionsLoading = false;
  String? _transactionsError;
  bool _transactionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _accountMasterService = AccountMasterService();

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_slotsLoaded) {
        _loadSlots();
      } else if (_tabController.index == 1 && !_transactionsLoaded) {
        _loadTransactions();
      }
    });

    // Load slots initially (first tab is active)
    _loadSlots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    if (_slotsLoaded || _slotsLoading) return;

    if (!mounted) return;
    setState(() {
      _slotsLoading = true;
      _slotsError = null;
    });

    try {
      setState(() {
        _slots = widget.accountMaster.slots ?? [];
        _slotsLoading = false;
        _slotsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = e.toString();
        _slotsLoading = false;
        _slotsLoaded = true;
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (_transactionsLoaded || _transactionsLoading) return;

    if (!mounted) return;
    setState(() {
      _transactionsLoading = true;
      _transactionsError = null;
    });

    try {
      final response = await _accountMasterService.getExpense(
        widget.accountMaster.id,
      );

      if (!mounted) return;
      setState(() {
        _transactions = response.data?.items ?? [];
        _transactionsLoading = false;
        _transactionsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transactionsError = e.toString();
        _transactionsLoading = false;
        _transactionsLoaded = true;
      });
    }
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  void _showCreateExpenseSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountMasterExpenseCreateScreen(
          accountMaster: widget.accountMaster,
        ),
      ),
    );
    if (result == true) {
      // Reload data if needed
      if (_tabController.index == 1) {
        setState(() {
          _transactionsLoaded = false;
        });
        _loadTransactions();
      }
    }
  }

  void _showEditAccountScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AccountMasterUpsertScreen(accountMaster: widget.accountMaster),
      ),
    );
    if (result == true) {
      // Reload would be handled by returning to list screen
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true);
    }
  }

  void _showAddSlotSheet() async {
    final newSlot = await showModalBottomSheet<AccountSlot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddSlotSheet(accountMaster: widget.accountMaster),
    );
    if (newSlot != null) {
      // Reload slots
      setState(() {
        _slotsLoaded = false;
      });
      _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountMaster.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'create_expense') {
                _showCreateExpenseSheet();
              } else if (value == 'edit_account') {
                _showEditAccountScreen();
              } else if (value == 'add_slot') {
                _showAddSlotSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_expense',
                child: Row(
                  children: [
                    Icon(Icons.add_card, size: 16),
                    SizedBox(width: 12),
                    Text('Tạo chi phí'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_account',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 12),
                    Text('Chỉnh sửa tài khoản'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_slot',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 12),
                    Text('Thêm slot'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Danh sách Slot'),
            Tab(text: 'Giao dịch chi phí'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Account Information + Slots
          _buildSlotsTab(),
          // Tab 1: Transactions
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildSlotsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Account Master Details Section
          _buildAccountDetailsCard(),
          const SizedBox(height: 16),
          // Slots Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách Slot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_slotsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_slotsError != null)
                  Center(
                    child: Text(
                      'Lỗi: $_slotsError',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (_slots.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Không có slot nào',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _slots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final slot = _slots[index];
                      return _buildSlotCard(slot);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    final accountMaster = widget.accountMaster;
    final serviceTypeLabel = enums.AccountMasterServiceType.values
        .firstWhere(
          (type) => type.value == accountMaster.serviceType,
          orElse: () => enums.AccountMasterServiceType.values.first,
        )
        .label;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tên tài khoản', accountMaster.name),
            _buildDetailRow('Username', accountMaster.username),
            _buildDetailRow('Loại dịch vụ', serviceTypeLabel),
            _buildDetailRow(
              'Số slot tối đa',
              accountMaster.maxSlots.toString(),
            ),
            if (accountMaster.monthlyCost != null)
              _buildDetailRow(
                'Chi phí hàng tháng',
                '${CurrencyHelper.formatCurrency(accountMaster.monthlyCost!)} VND',
              ),
            if (accountMaster.paymentDate != null)
              _buildDetailRow(
                'Ngày thanh toán',
                DateHelper.formatDate(accountMaster.paymentDate!),
              ),
            if (accountMaster.notes != null && accountMaster.notes!.isNotEmpty)
              _buildDetailRow('Ghi chú', accountMaster.notes!),
            _buildDetailRow(
              'Trạng thái',
              accountMaster.isActive ? 'Đang hoạt động' : 'Không hoạt động',
            ),
            if (accountMaster.createdAt != null)
              _buildDetailRow(
                'Ngày tạo',
                DateHelper.formatDate(accountMaster.createdAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSlotCard(AccountSlot slot) {
    final hasOrder = slot.shopOrderItem?.order != null;
    final customerName = hasOrder
        ? slot.shopOrderItem?.order?.user?.name
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot name and days until expiry
          Row(
            children: [
              Icon(Icons.label, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  slot.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                slot.daysUntilExpiry <= 0
                    ? 'Hết hạn'
                    : 'Còn ${slot.daysUntilExpiry} ngày',
                style: TextStyle(
                  fontSize: 12,
                  color: slot.daysUntilExpiry <= 3
                      ? Colors.red
                      : slot.daysUntilExpiry <= 0
                      ? Colors.red
                      : colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date information
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (slot.pin.isNotEmpty) ...[
                Expanded(child: _buildSlotInfo(Icons.vpn_key, 'PIN', slot.pin)),
              ],
              Expanded(
                child: _buildSlotInfo(
                  Icons.calendar_today,
                  'Từ',
                  slot.startDate != null
                      ? DateHelper.formatDateShort(slot.startDate!)
                      : 'N/A',
                ),
              ),
              Expanded(
                child: _buildSlotInfo(
                  Icons.event_busy,
                  'Đến',
                  slot.expiryDate != null
                      ? DateHelper.formatDateShort(slot.expiryDate!)
                      : 'N/A',
                ),
              ),
            ],
          ),

          // Customer name (if available)
          if (customerName != null && customerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailScreen(
                          user: slot.shopOrderItem!.order!.user!,
                        ),
                      ),
                    ),
                    child: _buildSlotInfo(Icons.person, '', customerName),
                  ),
                ),
                if (hasOrder)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(
                            orderId: slot.shopOrderItem!.orderId.toString(),
                          ),
                        ),
                      );
                    },
                    label: Text(
                      'Xem đơn hàng',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 14),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        if (label.isNotEmpty) ...[
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactionsError != null) {
      return Center(
        child: Text(
          'Lỗi: $_transactionsError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Không có giao dịch nào',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _transactions.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction) {
    final isExpense =
        transaction.type.toLowerCase() == 'expense' ||
        transaction.category.toLowerCase().contains('expense');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isExpense
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
        ),
        child: Icon(
          isExpense ? Icons.trending_down : Icons.trending_up,
          color: isExpense ? colorScheme.error : colorScheme.primary,
        ),
      ),
      title: Text(transaction.description ?? transaction.transactionId),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text(
            'Danh mục: ${transaction.category}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          if (transaction.createdAt != null)
            Text(
              DateHelper.formatDate(transaction.createdAt!),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${CurrencyHelper.formatCurrency(transaction.amount.toInt())} VND',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? colorScheme.error : colorScheme.primary,
            ),
          ),
          Text(
            transaction.status,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AddSlotSheet extends StatefulWidget {
  final AccountMaster accountMaster;

  const _AddSlotSheet({required this.accountMaster});

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountMasterService = AccountMasterService();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _accountMasterService.addSlot(
        widget.accountMaster.id,
        name: _nameController.text.trim(),
        pin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
      );

      if (!mounted) return;
      Toastr.success('Thêm slot thành công', context: context);
      Navigator.of(context).pop(response.data);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: ${e.toString()}', context: context);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Thêm slot mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên slot *',
                  hintText: 'Nhập tên slot',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên slot';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Nhập PIN (không bắt buộc)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: LoadingIcon(
                  icon: Icons.check_circle_outline_outlined,
                  loading: _isSubmitting,
                ),
                label: Text(_isSubmitting ? 'Đang thêm...' : 'Thêm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
