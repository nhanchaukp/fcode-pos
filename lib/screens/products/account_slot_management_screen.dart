import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

class AccountSlotManagementScreen extends StatefulWidget {
  const AccountSlotManagementScreen({super.key});

  @override
  State<AccountSlotManagementScreen> createState() =>
      _AccountSlotManagementScreenState();
}

class _AccountSlotManagementScreenState
    extends State<AccountSlotManagementScreen> {
  late AccountSlotService _accountSlotService;
  List<AccountMaster> _accountMasters = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedServiceType;
  bool? _selectedIsActive;
  String _searchQuery = '';
  int? _selectedDaysRemaining; // null means "Tất cả"

  final TextEditingController _searchController = TextEditingController();

  // Service types - you can customize this list
  final List<String> _serviceTypes = [
    'Netflix',
    'Spotify',
    'YouTube',
    'ChatGpt',
  ];

  @override
  void initState() {
    super.initState();
    _accountSlotService = AccountSlotService();
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
        serviceType: _selectedServiceType,
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
                  DropdownButtonFormField<String>(
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
                      ..._serviceTypes.map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_selectedServiceType != null)
                      Chip(
                        label: Text('Loại: $_selectedServiceType'),
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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAccounts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final accountMaster = filteredAccounts[index];
          return _buildAccountMasterCard(accountMaster);
        },
      ),
    );
  }

  Widget _buildAccountMasterCard(AccountMaster accountMaster) {
    final slots = accountMaster.slots ?? const <AccountSlot>[];
    final hasSlots = slots.isNotEmpty;
    final slotCountLabel = '${slots.length}/${accountMaster.maxSlots} slots';
    final infoItems = <String>[
      if (accountMaster.serviceType.isNotEmpty)
        accountMaster.serviceType.toUpperCase(),
      if (accountMaster.paymentDate != null)
        'Gia hạn ${DateHelper.formatDateShort(accountMaster.paymentDate!)}',
    ];
    final infoText = infoItems.join(' • ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    accountMaster.name,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(accountMaster.isActive),
              ],
            ),
            if (infoText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                infoText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if ((accountMaster.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(
                    colorScheme.brightness == Brightness.dark ? 0.35 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        accountMaster.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (hasSlots) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.dns_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách $slotCountLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...slots.map(_buildSlotItem),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Không có slot nào',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotItem(AccountSlot slot) {
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
          // Slot name and order button
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
                    overflow: TextOverflow.ellipsis,
                  ),
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
            children: [
              Expanded(
                child: _buildSlotInfo(
                  Icons.calendar_today,
                  'Bắt đầu',
                  slot.startDate != null
                      ? DateHelper.formatDateShort(slot.startDate!)
                      : 'N/A',
                ),
              ),
              Expanded(
                child: _buildSlotInfo(
                  Icons.event_busy,
                  'Hết hạn',
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
                    child: _buildSlotInfo(Icons.person, 'Khách', customerName),
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
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
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

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
