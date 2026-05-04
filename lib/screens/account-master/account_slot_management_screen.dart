import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/audit/audit_log_screen.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_expense_create_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_upsert_screen.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/string_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountSlotManagementScreen extends StatefulWidget {
  const AccountSlotManagementScreen({super.key});

  @override
  State<AccountSlotManagementScreen> createState() =>
      _AccountSlotManagementScreenState();
}

class _AccountSlotManagementScreenState
    extends State<AccountSlotManagementScreen> {
  late AccountSlotService _accountSlotService;
  late AccountMasterService _accountMasterService;
  List<AccountMaster> _accountMasters = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  enums.AccountMasterServiceType? _selectedServiceType;
  bool? _selectedIsActive;
  String _searchQuery = '';
  int? _selectedDaysRemaining; // null means "Tất cả"

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accountSlotService = AccountSlotService();
    _accountMasterService = AccountMasterService();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
    _loadAccountMasters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  Future<void> _loadAccountMasters() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _accountSlotService.listMaster(
        serviceType: _selectedServiceType?.value,
        isActive: _selectedIsActive,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        daysRemaining: _selectedDaysRemaining,
      );

      if (!mounted) return;
      setState(() {
        _accountMasters = response.data ?? [];
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrintStack(
        stackTrace: st,
        label: 'Error loading account masters: ${e.toString()}',
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateExpenseSheet(AccountMaster accountMaster) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AccountMasterExpenseCreateScreen(accountMaster: accountMaster),
      ),
    );
    if (result == true) {
      _loadAccountMasters();
    }
  }

  void _showEditAccountScreen(AccountMaster accountMaster) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AccountMasterUpsertScreen(accountMaster: accountMaster),
      ),
    );
    if (result == true) {
      _loadAccountMasters();
    }
  }

  void _applyFilters() {
    _loadAccountMasters();
  }

  void _resetFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedIsActive = null;
      _selectedDaysRemaining = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadAccountMasters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Type Filter
                  const Text(
                    'Loại dịch vụ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<enums.AccountMasterServiceType>(
                    initialValue: _selectedServiceType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tất cả',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...enums.AccountMasterServiceType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedServiceType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Active Status Filter
                  const Text(
                    'Trạng thái',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<bool?>(
                    initialValue: _selectedIsActive,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tất cả',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả')),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Đang hoạt động'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Không hoạt động'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedIsActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Days Remaining Filter
                  const Text(
                    'Số ngày còn lại',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedDaysRemaining == null,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedDaysRemaining = null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('≤ 1 ngày'),
                        selected: _selectedDaysRemaining == 1,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedDaysRemaining = selected ? 1 : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('≤ 3 ngày'),
                        selected: _selectedDaysRemaining == 3,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedDaysRemaining = selected ? 3 : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('≤ 5 ngày'),
                        selected: _selectedDaysRemaining == 5,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedDaysRemaining = selected ? 5 : null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _resetFilters();
              Navigator.pop(context);
            },
            child: const Text('Đặt lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                // Apply the filter values from dialog
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        title: SearchBar(
          controller: _searchController,
          hintText: 'Tìm theo tên, username',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                tooltip: 'Xóa',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadAccountMasters();
                },
              ),
            IconButton(
              icon: Badge(
                isLabelVisible:
                    _selectedServiceType != null ||
                    _selectedIsActive != null ||
                    _selectedDaysRemaining != null,
                child: const Icon(Icons.filter_list),
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Bộ lọc',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountMasterUpsertScreen(),
                  ),
                );
                if (result == true) {
                  _loadAccountMasters();
                }
              },
              tooltip: 'Tạo tài khoản',
            ),
          ],
          onSubmitted: (_) => _loadAccountMasters(),
          textInputAction: TextInputAction.search,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
      body: Column(
        children: [
          // Active filters display
          if (_selectedServiceType != null ||
              _selectedIsActive != null ||
              _selectedDaysRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedServiceType != null)
                    Chip(
                      label: Text('Loại: ${_selectedServiceType!.label}'),
                      onDeleted: () {
                        setState(() {
                          _selectedServiceType = null;
                        });
                        _loadAccountMasters();
                      },
                    ),
                  if (_selectedIsActive != null)
                    Chip(
                      label: Text(
                        _selectedIsActive!
                            ? 'Đang hoạt động'
                            : 'Không hoạt động',
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedIsActive = null;
                        });
                        _loadAccountMasters();
                      },
                    ),
                  if (_selectedDaysRemaining != null)
                    Chip(
                      label: Text('Còn ≤ $_selectedDaysRemaining ngày'),
                      onDeleted: () {
                        setState(() {
                          _selectedDaysRemaining = null;
                        });
                        _loadAccountMasters();
                      },
                    ),
                ],
              ),
            ),

          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAccountMasters,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Apply local filter for daysRemaining
    var filteredAccounts = _accountMasters;
    if (_selectedDaysRemaining != null) {
      filteredAccounts = _accountMasters.where((account) {
        if (account.slots == null || account.slots!.isEmpty) return false;
        // Check if any slot has daysUntilExpiry <= selected days
        return account.slots!.any(
          (slot) => slot.daysUntilExpiry <= _selectedDaysRemaining!,
        );
      }).toList();
    }

    if (filteredAccounts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAccountMasters,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(child: Text('Không tìm thấy tài khoản nào')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccountMasters,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: filteredAccounts.length,
        itemBuilder: (context, index) {
          return _buildAccountMasterCard(filteredAccounts[index]);
        },
      ),
    );
  }

  Widget _buildAccountMasterCard(AccountMaster accountMaster) {
    final hasSlots =
        accountMaster.slots != null && accountMaster.slots!.isNotEmpty;
    final hasNotes =
        accountMaster.notes != null && accountMaster.notes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account header ────────────────────────────────────────────────
          ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AccountMasterDetailScreen(accountMaster: accountMaster),
              ),
            ),
            contentPadding:
                const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
            leading: _ServiceBadge(serviceType: accountMaster.serviceType),
            title: Text(
              accountMaster.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                _StatusDot(isActive: accountMaster.isActive),
                const SizedBox(width: 4),
                Text(
                  accountMaster.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        accountMaster.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (accountMaster.paymentDate != null) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(color: colorScheme.outlineVariant),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    DateHelper.formatDateShort(accountMaster.paymentDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'create_expense') {
                  _showCreateExpenseSheet(accountMaster);
                } else if (value == 'edit_account') {
                  _showEditAccountScreen(accountMaster);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'create_expense',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add_card, size: 18),
                    title: Text('Tạo chi phí'),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit_account',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('Chỉnh sửa tài khoản'),
                  ),
                ),
              ],
            ),
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      accountMaster.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Slots ─────────────────────────────────────────────────────────
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.dns_outlined, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Slots  ${accountMaster.slots?.length ?? 0}/${accountMaster.maxSlots}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          if (!hasSlots)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Không có slot nào',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...accountMaster.slots!.asMap().entries.map((e) {
              final isLast = e.key == accountMaster.slots!.length - 1;
              return _buildSlotItem(e.value, accountMaster, isLast: isLast);
            }),
        ],
      ),
    );
  }

  void _showSlotItemMenu(
    BuildContext context,
    AccountSlot slot,
    AccountMaster accountMaster,
  ) {
    final hasOrder = slot.shopOrderItem?.order != null;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasOrder)
              ListTile(
                leading: const Icon(Icons.link_off),
                title: const Text('Gỡ liên kết đơn hàng'),
                onTap: () {
                  Navigator.pop(context);
                  _unlinkOrderFromSlot(slot);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép thông tin'),
              onTap: () {
                Navigator.pop(context);
                _copySlotInfo(slot);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditSlotSheet(slot);
              },
            ),
            if (hasOrder)
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Xem đơn hàng'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(
                        orderId: slot.shopOrderItem!.orderId.toString(),
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử thay đổi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuditLogScreen(
                      title: slot.name,
                      fetcher: (page) => _accountSlotService.audits(
                        slot.id,
                        page: page,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlinkOrderFromSlot(AccountSlot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ liên kết đơn hàng'),
        content: const Text(
          'Bạn có chắc muốn gỡ liên kết đơn hàng khỏi slot này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gỡ liên kết'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final response = await _accountSlotService.unlinkOrder(
        slot.id.toString(),
      );
      if (!mounted) return;
      if (response.success) {
        Toastr.success('Đã gỡ liên kết đơn hàng', context: context);
        _loadAccountMasters();
      } else {
        Toastr.error(
          response.message ?? 'Gỡ liên kết thất bại',
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi: ${e.toString()}', context: context);
      }
    }
  }

  Future<void> _copySlotInfo(AccountSlot slot) async {
    final copyText = StringHelper.formatSlotCopyText(slot);

    await Clipboard.setData(ClipboardData(text: copyText));

    if (mounted) {
      Toastr.success('Đã copy thông tin tài khoản', context: context);
    }
  }

  void _showEditSlotSheet(AccountSlot slot) async {
    final result = await showModalBottomSheet<AccountSlot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EditSlotSheet(
        slot: slot,
        accountMasterService: _accountMasterService,
      ),
    );
    if (result != null && mounted) {
      _loadAccountMasters();
    }
  }

  Widget _buildSlotItem(
    AccountSlot slot,
    AccountMaster accountMaster, {
    bool isLast = false,
  }) {
    final hasOrder = slot.shopOrderItem?.order != null;
    final customerName = hasOrder ? slot.shopOrderItem?.order?.user?.name : null;
    final days = slot.daysUntilExpiry;
    final expiryColor = days <= 0
        ? Colors.red
        : days <= 3
            ? Colors.orange
            : days <= 7
                ? Colors.amber.shade700
                : Colors.green;

    final startStr = slot.startDate != null
        ? DateHelper.formatDateShort(slot.startDate!)
        : 'N/A';
    final endStr = slot.expiryDate != null
        ? DateHelper.formatDateShort(slot.expiryDate!)
        : 'N/A';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onLongPress: () => _showSlotItemMenu(context, slot, accountMaster),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expiry dot
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: expiryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Slot details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Text(
                        slot.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Date + PIN row
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        child: Wrap(
                          spacing: 10,
                          children: [
                            if (slot.pin.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.vpn_key,
                                      size: 11,
                                      color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text(
                                    slot.pin,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.date_range,
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text('$startStr → $endStr'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Customer row
                      if (customerName != null && customerName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 11, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      user: slot
                                          .shopOrderItem!.order!.user!,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  customerName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (hasOrder)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(
                                      orderId: slot.shopOrderItem!.orderId
                                          .toString(),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Đơn hàng →',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Expiry badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: expiryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    days <= 0 ? 'Hết hạn' : '$days ngày',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: expiryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 38,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.serviceType});
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        serviceType.isNotEmpty ? serviceType[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EditSlotSheet extends StatefulWidget {
  final AccountSlot slot;
  final AccountMasterService accountMasterService;

  const _EditSlotSheet({
    required this.slot,
    required this.accountMasterService,
  });

  @override
  State<_EditSlotSheet> createState() => _EditSlotSheetState();
}

class _EditSlotSheetState extends State<_EditSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.slot.name);
    _pinController = TextEditingController(text: widget.slot.pin);
  }

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
      final response = await widget.accountMasterService.updateSlot(
        widget.slot.id,
        name: _nameController.text.trim(),
        pin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        Toastr.success('Cập nhật slot thành công', context: context);
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error(response.message ?? 'Cập nhật thất bại', context: context);
      }
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
                    'Chỉnh sửa slot',
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
                label: Text(_isSubmitting ? 'Đang cập nhật...' : 'Cập nhật'),
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
