import 'dart:convert';

import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/account-master/account_master_browser_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_expense_create_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_upsert_screen.dart';
import 'package:fcode_pos/screens/account-master/account_slot_detail_screen.dart';
import 'package:fcode_pos/screens/audit/audit_log_screen.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/account_master_browser_session.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/app_tab.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/ui/components/badge/service_badge.dart';
import 'package:fcode_pos/ui/components/badge/status_badges.dart';
import 'package:fcode_pos/ui/components/slot_edit_sheet.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/string_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late AccountSlotService _accountSlotService;

  // Fresh account master data
  late AccountMaster _accountMaster;
  bool _syncingNetflix = false;

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
  bool _externalConfigExpanded = false;

  @override
  void initState() {
    super.initState();
    _accountMaster = widget.accountMaster;
    _tabController = TabController(length: 2, vsync: this);
    _accountMasterService = AccountMasterService();
    _accountSlotService = AccountSlotService();

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_slotsLoaded) {
        _loadSlots();
      } else if (_tabController.index == 1 && !_transactionsLoaded) {
        _loadTransactions();
      }
    });

    // Fetch fresh data from service, then load slots
    _fetchAccountMaster();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccountMaster() async {
    if (!mounted) return;

    try {
      final response = await _accountMasterService.getById(
        widget.accountMaster.id,
      );
      if (!mounted) return;
      setState(() {
        _accountMaster = response.data ?? _accountMaster;
        _slots = _accountMaster.slots ?? _slots;
        _slotsLoaded = true;
        _slotsLoading = false;
        _slotsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      _loadSlots();
    }
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
        _slots = _accountMaster.slots ?? [];
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

  bool get _isNetflix =>
      _accountMaster.serviceType ==
      enums.AccountMasterServiceType.netflix.value;

  Future<void> _syncNetflixInfo() async {
    if (_syncingNetflix) return;

    setState(() => _syncingNetflix = true);
    try {
      await Toastr.promise<void>(
        () async {
          final response = await _accountMasterService.syncNetflixInfo(
            _accountMaster.id,
          );
          if (!mounted) return;

          setState(() {
            _accountMaster = response.data ?? _accountMaster;
            _slots = _accountMaster.slots ?? _slots;
            _slotsLoaded = true;
          });
        }(),
        loading: 'Đang đồng bộ thông tin Netflix...',
        success: 'Đồng bộ thành công',
        errorBuilder: (e) => 'Lỗi: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _syncingNetflix = false);
      }
    }
  }

  void _showCreateExpenseSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AccountMasterExpenseCreateScreen(accountMaster: _accountMaster),
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
            AccountMasterUpsertScreen(accountMaster: _accountMaster),
      ),
    );
    if (result == true && mounted) {
      await _fetchAccountMaster();
    }
  }

  Future<AccountMaster?> _pushBrowserScreen(
    BuildContext navigatorContext,
    AccountMasterBrowserSession session,
  ) {
    return Navigator.push<AccountMaster>(
      navigatorContext,
      MaterialPageRoute<AccountMaster>(
        builder: (context) => AccountMasterBrowserScreen(session: session),
      ),
    );
  }

  Future<AccountMaster?> _expandBrowserFromSession(
    BuildContext context,
    AccountMasterBrowserSession session,
  ) async {
    final result = await _pushBrowserScreen(context, session);
    if (result != null && mounted) {
      setState(() => _accountMaster = result);
    }
    return result;
  }

  void _openInAppBrowser() async {
    final session = await AccountMasterBrowserSession.start(
      accountMaster: _accountMaster,
    );
    if (!mounted) return;

    session.onExpand = _expandBrowserFromSession;

    final result = await _pushBrowserScreen(context, session);

    if (result != null && mounted) {
      setState(() => _accountMaster = result);
    }
  }

  Future<void> _showAddSlotSheet() async {
    final newSlot = await showModalBottomSheet<AccountSlot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddSlotSheet(accountMaster: _accountMaster),
    );
    if (newSlot != null) {
      await _refreshAccountAndSlots();
    }
  }

  void _showGetAllCodeBottomSheet() {
    showGetAllCodeBottomSheet(
      context,
      accountMaster: _accountMaster,
      accountMasterService: _accountMasterService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: _accountMaster.name,
      subtitle: _accountMaster.username,
      actions: [
        IconButton(
          icon: const Icon(Icons.vpn_key_outlined),
          visualDensity: VisualDensity.compact,
          tooltip: 'Lấy mã & link xác minh',
          onPressed: _showGetAllCodeBottomSheet,
        ),
        IconButton(
          icon: const Icon(Icons.language),
          visualDensity: VisualDensity.compact,
          tooltip: 'Mở trình duyệt',
          onPressed: _openInAppBrowser,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'get_all_code') {
              _showGetAllCodeBottomSheet();
            } else if (value == 'create_expense') {
              _showCreateExpenseSheet();
            } else if (value == 'edit_account') {
              _showEditAccountScreen();
            } else if (value == 'add_slot') {
              _showAddSlotSheet();
            } else if (value == 'sync_netflix') {
              _syncNetflixInfo();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'get_all_code',
              child: Row(
                children: [
                  Icon(Icons.vpn_key_outlined, size: 16),
                  SizedBox(width: 12),
                  Text('Lấy mã & link xác minh'),
                ],
              ),
            ),
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
            if (_isNetflix)
              PopupMenuItem(
                value: 'sync_netflix',
                enabled: !_syncingNetflix,
                child: const Row(
                  children: [
                    Icon(Icons.sync, size: 16),
                    SizedBox(width: 12),
                    Text('Đồng bộ thông tin Netflix'),
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
      body: (context, _) => Column(
        children: [
          Material(
            color: cs.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                AppTab(icon: Icons.dns_outlined, text: 'Danh sách Slot'),
                AppTab(
                  icon: Icons.receipt_long_outlined,
                  text: 'Giao dịch chi phí',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSlotsTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAccountAndSlots() async {
    setState(() {
      _slotsLoaded = false;
      _slotsLoading = false;
    });
    await _fetchAccountMaster();
  }

  Future<void> _refreshTransactions() async {
    if (!mounted) return;

    try {
      final response = await _accountMasterService.getExpense(
        widget.accountMaster.id,
      );
      if (!mounted) return;
      setState(() {
        _transactions = response.data?.items ?? [];
        _transactionsLoaded = true;
        _transactionsLoading = false;
        _transactionsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transactionsError = e.toString();
        _transactionsLoaded = true;
        _transactionsLoading = false;
      });
    }
  }

  double get _tabBodyMinHeight {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        kToolbarHeight -
        kTextTabBarHeight;
  }

  Widget _buildSlotsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAccountAndSlots,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _tabBodyMinHeight),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildAccountInfoCard(),
                    const SizedBox(height: 12),
                    _buildSlotsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    Toastr.success('Đã sao chép $label', context: context);
  }

  Widget _buildCopyIconButton({required String label, required String value}) {
    return IconButton(
      icon: Icon(Icons.copy_outlined, size: 14, color: colorScheme.primary),
      tooltip: 'Sao chép $label',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _copyToClipboard(label, value),
    );
  }

  Widget _buildAccountInfoCard() {
    final accountMaster = _accountMaster;
    final serviceTypeLabel = enums.AccountMasterServiceType.values
        .firstWhere(
          (type) => type.value == accountMaster.serviceType,
          orElse: () => enums.AccountMasterServiceType.values.first,
        )
        .label;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: 4,
            ),
            leading: ServiceBadge(serviceType: accountMaster.serviceType),
            title: Text(
              accountMaster.name,
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
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Column(
              children: [
                _buildCopyableDetailRow('Username', accountMaster.username),
                _buildCopyableDetailRow('Password', accountMaster.password),
                _buildDetailRow('Loại dịch vụ', serviceTypeLabel),
                _buildDetailRow(
                  'Nhà cung cấp',
                  accountMaster.supply?.name ?? '-',
                ),
                _buildDetailRow(
                  'Số slot',
                  '${_slots.length}/${accountMaster.maxSlots}',
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
                if (accountMaster.notes != null &&
                    accountMaster.notes!.isNotEmpty)
                  _buildDetailRow('Ghi chú', accountMaster.notes!),
                if (accountMaster.costNotes != null &&
                    accountMaster.costNotes!.isNotEmpty)
                  _buildDetailRow('Ghi chú chi phí', accountMaster.costNotes!),
                if (accountMaster.externalSrc != null &&
                    accountMaster.externalSrc!.isNotEmpty)
                  _buildCopyableDetailRow(
                    'External Src',
                    accountMaster.externalSrc!,
                  ),
                if (accountMaster.externalConfig != null &&
                    accountMaster.externalConfig!.isNotEmpty)
                  _buildExternalConfigRow(accountMaster.externalConfig!),
                _buildDetailRow(
                  'Trạng thái',
                  accountMaster.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                ),
                if (accountMaster.createdAt != null)
                  _buildDetailRow(
                    'Ngày tạo',
                    DateHelper.formatDate(accountMaster.createdAt!),
                  ),
                if (accountMaster.updatedAt != null)
                  _buildDetailRow(
                    'Cập nhật lần cuối',
                    DateHelper.formatDate(accountMaster.updatedAt!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalConfigRow(Map<String, dynamic> config) {
    final jsonText = const JsonEncoder.withIndent('  ').convert(config);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _externalConfigExpanded = !_externalConfigExpanded,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      'Config',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _externalConfigExpanded
                          ? 'JSON'
                          : '${config.length} trường · chạm để xem',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _externalConfigExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  _buildCopyIconButton(label: 'Config', value: jsonText),
                ],
              ),
            ),
          ),
          if (_externalConfigExpanded) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: SelectableText(
                jsonText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _buildCopyIconButton(label: label, value: value),
        ],
      ),
    );
  }

  Widget _buildSlotsCard() {
    final accountMaster = _accountMaster;
    final hasSlots = _slots.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
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
                  'Slots  ${_slots.length}/${accountMaster.maxSlots}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          if (_slotsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_slotsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Lỗi: $_slotsError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else if (!hasSlots)
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
            ..._slots.asMap().entries.map((e) {
              final isLast = e.key == _slots.length - 1;
              return _buildSlotItem(e.value, isLast: isLast);
            }),
        ],
      ),
    );
  }

  void _showSlotItemMenu(BuildContext context, AccountSlot slot) {
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
                  await _refreshAccountAndSlots();
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
        await _refreshAccountAndSlots();
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
      await _refreshAccountAndSlots();
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
        await _refreshAccountAndSlots();
      } else {
        Toastr.error(response.message ?? 'Xóa slot thất bại', context: context);
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi: ${e.toString()}', context: context);
      }
    }
  }

  Widget _buildSlotItem(AccountSlot slot, {bool isLast = false}) {
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
              await _refreshAccountAndSlots();
            }
          },
          onLongPress: () => _showSlotItemMenu(context, slot),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

  Widget _buildTransactionsTab() {
    if (_transactionsLoading && !_transactionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      child: _transactions.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: _tabBodyMinHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _transactionsError != null
                            ? 'Lỗi: $_transactionsError'
                            : 'Không có giao dịch nào',
                        style: TextStyle(
                          color: _transactionsError != null
                              ? Colors.red
                              : colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _transactions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 54,
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction) {
    final isExpense =
        transaction.type.toLowerCase() == 'expense' ||
        transaction.category.toLowerCase().contains('expense');
    final textTheme = Theme.of(context).textTheme;
    final description = transaction.description ?? transaction.transactionId;
    final dateLabel = transaction.createdAt != null
        ? DateHelper.formatDate(transaction.createdAt!)
        : null;
    final metaParts = <String>[
      transaction.category,
      ?dateLabel,
      transaction.status,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isExpense
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
            ),
            child: Icon(
              isExpense ? Icons.trending_down : Icons.trending_up,
              size: 16,
              color: isExpense ? colorScheme.error : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metaParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyHelper.formatCurrency(transaction.amount.toInt()),
            style: textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isExpense ? colorScheme.error : colorScheme.primary,
              height: 1.2,
            ),
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


