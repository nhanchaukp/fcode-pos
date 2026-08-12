import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/account_slot/account_slot_filter_provider.dart';
import 'package:fcode_pos/screens/audit/audit_log_screen.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_slot_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_expense_create_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_upsert_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_filter_sheet.dart';
import 'package:fcode_pos/screens/account-master/account_master_stats_screen.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/string_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/slot_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:fcode_pos/ui/components/badge/service_badge.dart';
import 'package:fcode_pos/ui/components/badge/status_badges.dart';

class AccountSlotManagementScreen extends ConsumerStatefulWidget {
  const AccountSlotManagementScreen({super.key});

  @override
  ConsumerState<AccountSlotManagementScreen> createState() =>
      _AccountSlotManagementScreenState();
}

class _AccountSlotManagementScreenState
    extends ConsumerState<AccountSlotManagementScreen> {
  late AccountSlotService _accountSlotService;
  late AccountMasterService _accountMasterService;
  List<AccountMaster> _accountMasters = [];
  bool _isLoading = false;
  String? _error;

  // Filters (đồng bộ với accountSlotFilterProvider)
  enums.AccountMasterServiceType? _selectedServiceType;
  bool? _selectedIsActive;
  bool _selectedIsFreeSlot = false;
  Supply? _selectedSupply;
  int? _selectedDaysRemaining; // null means "Tất cả"

  final TextEditingController _searchController = TextEditingController();

  bool get _hasFilters =>
      _selectedServiceType != null ||
      _selectedIsActive != null ||
      _selectedDaysRemaining != null ||
      _selectedIsFreeSlot ||
      _selectedSupply != null;

  @override
  void initState() {
    super.initState();
    _accountSlotService = AccountSlotService();
    _accountMasterService = AccountMasterService();

    final filter = ref.read(accountSlotFilterProvider);
    _searchController.text = filter.search;
    _selectedServiceType = filter.serviceType;
    _selectedIsActive = filter.isActive;
    _selectedIsFreeSlot = filter.isFreeSlot;
    _selectedSupply = filter.supply;
    _selectedDaysRemaining = filter.daysRemaining;

    _loadAccountMasters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  void _persistFilter({String? search}) {
    ref.read(accountSlotFilterProvider.notifier).state = AccountSlotFilter(
      search: search ?? _searchController.text.trim(),
      serviceType: _selectedServiceType,
      isActive: _selectedIsActive,
      isFreeSlot: _selectedIsFreeSlot,
      supply: _selectedSupply,
      daysRemaining: _selectedDaysRemaining,
    );
  }

  void _applySearch(String value) {
    _persistFilter(search: value.trim());
    _loadAccountMasters();
  }

  Future<void> _loadAccountMasters() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final filter = ref.read(accountSlotFilterProvider);

    try {
      final response = await _accountSlotService.listMaster(
        serviceType: filter.serviceType?.value,
        isActive: filter.isActive,
        search: filter.search.isEmpty ? null : filter.search,
        daysRemaining: filter.daysRemaining,
        isFreeSlot: filter.isFreeSlot ? true : null,
        supplyId: filter.supply?.id,
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

  void _resetFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedIsActive = null;
      _selectedIsFreeSlot = false;
      _selectedSupply = null;
      _selectedDaysRemaining = null;
    });
    _searchController.clear();
    ref.read(accountSlotFilterProvider.notifier).state =
        const AccountSlotFilter();
    _loadAccountMasters();
  }

  void _showFilterBottomSheet() {
    final currentFilter = AccountSlotFilter(
      search: _searchController.text.trim(),
      serviceType: _selectedServiceType,
      isActive: _selectedIsActive,
      isFreeSlot: _selectedIsFreeSlot,
      supply: _selectedSupply,
      daysRemaining: _selectedDaysRemaining,
    );

    AccountMasterFilterSheet.show(
      context,
      initialFilter: currentFilter,
      onReset: () {
        _resetFilters();
      },
      onApply: (newFilter) {
        setState(() {
          _selectedServiceType = newFilter.serviceType;
          _selectedIsActive = newFilter.isActive;
          _selectedIsFreeSlot = newFilter.isFreeSlot;
          _selectedSupply = newFilter.supply;
          _selectedDaysRemaining = newFilter.daysRemaining;
        });
        _persistFilter();
        _loadAccountMasters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kho tài khoản',
      enableSearch: true,
      searchHint: 'Tìm theo tên, ghi chú...',
      searchController: _searchController,
      onSearchChanged: _applySearch,
      onSearchSubmitted: _applySearch,
      actions: [
        IconButton(
          tooltip: 'Thống kê',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountMasterStatsScreen(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Tạo tài khoản',
          visualDensity: VisualDensity.compact,
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
        ),
        IconButton(
          tooltip: 'Bộ lọc',
          visualDensity: VisualDensity.compact,
          icon: Badge(
            isLabelVisible: _hasFilters,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterBottomSheet,
        ),
        if (_hasFilters)
          IconButton(
            tooltip: 'Xóa bộ lọc',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.clear),
            onPressed: _resetFilters,
          ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_hasFilters) _buildActiveFilterChips(),
          Expanded(child: _buildBody(scrollController)),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[
      if (_selectedServiceType != null)
        _ActiveFilterChip(
          label: _selectedServiceType!.label,
          onDeleted: () => _removeFilter(() => _selectedServiceType = null),
        ),
      if (_selectedIsActive != null)
        _ActiveFilterChip(
          label: _selectedIsActive! ? 'Hoạt động' : 'Không hoạt động',
          onDeleted: () => _removeFilter(() => _selectedIsActive = null),
        ),
      if (_selectedDaysRemaining != null)
        _ActiveFilterChip(
          label: '≤ $_selectedDaysRemaining ngày',
          onDeleted: () => _removeFilter(() => _selectedDaysRemaining = null),
        ),
      if (_selectedIsFreeSlot)
        _ActiveFilterChip(
          label: 'Còn slot',
          onDeleted: () => _removeFilter(() => _selectedIsFreeSlot = false),
        ),
      if (_selectedSupply != null)
        _ActiveFilterChip(
          label: _selectedSupply!.name,
          onDeleted: () => _removeFilter(() => _selectedSupply = null),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  void _removeFilter(VoidCallback update) {
    setState(update);
    _persistFilter();
    _loadAccountMasters();
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading && _accountMasters.isEmpty && _error == null) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null && _accountMasters.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Lỗi: $_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAccountMasters,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Apply local filter for daysRemaining
    var filteredAccounts = _accountMasters;
    if (_selectedDaysRemaining != null) {
      filteredAccounts = _accountMasters.where((account) {
        if (account.slots == null || account.slots!.isEmpty) return false;
        return account.slots!.any(
          (slot) => slot.daysUntilExpiry <= _selectedDaysRemaining!,
        );
      }).toList();
    }

    if (filteredAccounts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAccountMasters,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const Center(child: Text('Không tìm thấy tài khoản nào')),
            ),
          ],
        ),
      );
    }

    return DefaultStickyHeaderController(
      child: RefreshIndicator(
        onRefresh: _loadAccountMasters,
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            for (var i = 0; i < filteredAccounts.length; i++) ...[
              if (i > 0) const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildAccountStickySection(filteredAccounts[i]),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  SliverStickyHeader _buildAccountStickySection(AccountMaster accountMaster) {
    return SliverStickyHeader(
      header: _buildAccountHeader(accountMaster),
      sliver: SliverToBoxAdapter(child: _buildAccountBody(accountMaster)),
    );
  }

  Widget _buildAccountHeader(AccountMaster accountMaster) {
    final hasNotes =
        accountMaster.notes != null && accountMaster.notes!.isNotEmpty;
    final hasCostNotes =
        accountMaster.costNotes != null && accountMaster.costNotes!.isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AccountMasterDetailScreen(accountMaster: accountMaster),
              ),
            ),
            contentPadding: const EdgeInsets.only(
              left: 16,
              right: 4,
              top: 0,
              bottom: 0,
            ),
            leading: ServiceBadge(serviceType: accountMaster.serviceType),
            title: Text(
              accountMaster.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                ActiveStatusBadge(
                  isActive: accountMaster.isActive,
                  isGhost: true,
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
                if (accountMaster.supply != null) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(color: colorScheme.outlineVariant),
                  ),
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      accountMaster.supply!.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
          if (hasCostNotes)
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, hasNotes ? 8 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chi phí: ${accountMaster.costNotes!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBody(AccountMaster accountMaster) {
    final hasSlots =
        accountMaster.slots != null && accountMaster.slots!.isNotEmpty;

    return Material(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Xem chi tiết slot'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountSlotDetailScreen(slot: slot),
                  ),
                );
                if (result == true && mounted) {
                  _loadAccountMasters();
                }
              },
            ),
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
                      fetcher: (page) =>
                          _accountSlotService.audits(slot.id, page: page),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Xóa slot',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteSlot(slot);
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
    final result = await showSlotEditSheet(
      context,
      slot: slot,
      service: _accountMasterService,
    );
    if (result != null && mounted) {
      _loadAccountMasters();
    }
  }

  Future<void> _deleteSlot(AccountSlot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa slot?'),
        content: Text('Bạn có chắc muốn xóa "${slot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final response = await _accountSlotService.delete(slot.id.toString());
      if (!mounted) return;
      if (response.success) {
        Toastr.success('Đã xóa slot', context: context);
        _loadAccountMasters();
      } else {
        Toastr.error(response.message ?? 'Xóa slot thất bại', context: context);
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi: ${e.toString()}', context: context);
      }
    }
  }

  Widget _buildSlotItem(
    AccountSlot slot,
    AccountMaster accountMaster, {
    bool isLast = false,
  }) {
    final hasOrder = slot.shopOrderItem?.order != null;
    final customerName = hasOrder
        ? slot.shopOrderItem?.order?.user?.name
        : null;
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountSlotDetailScreen(slot: slot),
              ),
            );
            if (result == true && mounted) {
              _loadAccountMasters();
            }
          },
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
                                  Icon(
                                    Icons.vpn_key,
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    slot.pin,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.date_range,
                                  size: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
                            Icon(
                              Icons.person,
                              size: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      user: slot.shopOrderItem!.order!.user!,
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
                DaysRemainingBadge(days: days),
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

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDeleted,
      // visualDensity: VisualDensity.compact,
      // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      // labelPadding: const EdgeInsets.only(left: 8, right: 2),
      // deleteIconBoxConstraints: const BoxConstraints(
      //   minWidth: 22,
      //   minHeight: 22,
      // ),
    );
  }
}


