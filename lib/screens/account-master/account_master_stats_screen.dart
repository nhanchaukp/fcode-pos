import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/account_master_filter.dart';
import 'package:fcode_pos/providers/account_slot/account_slot_filter_provider.dart';
import 'package:fcode_pos/screens/account-master/account_master_batch_expense_create_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_detail_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_excel_column_sheet.dart';
import 'package:fcode_pos/screens/account-master/account_master_filter_sheet.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/utils/account_master_excel_helper.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';

class AccountMasterStatsScreen extends StatefulWidget {
  const AccountMasterStatsScreen({super.key});

  @override
  State<AccountMasterStatsScreen> createState() =>
      _AccountMasterStatsScreenState();
}

class _AccountMasterStatsScreenState extends State<AccountMasterStatsScreen> {
  final AccountMasterService _accountMasterService = AccountMasterService();
  final TextEditingController _searchController = TextEditingController();

  AccountMasterStats? _stats;
  List<AccountMaster> _accounts = [];
  Set<int> _selectedAccountIds = {};
  Set<AccountMasterExcelColumn>? _selectedExcelColumns;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  // Filter state
  enums.AccountMasterServiceType? _selectedServiceType;
  bool? _selectedIsActive;
  bool _selectedIsFreeSlot = false;
  Supply? _selectedSupply;
  int? _selectedDaysRemaining;

  bool get _hasFilters =>
      _selectedServiceType != null ||
      _selectedIsActive != null ||
      _selectedDaysRemaining != null ||
      _selectedIsFreeSlot ||
      _selectedSupply != null ||
      _searchController.text.trim().isNotEmpty;

  AccountSlotFilter get _currentFilter => AccountSlotFilter(
    search: _searchController.text.trim(),
    serviceType: _selectedServiceType,
    isActive: _selectedIsActive,
    isFreeSlot: _selectedIsFreeSlot,
    supply: _selectedSupply,
    daysRemaining: _selectedDaysRemaining,
  );

  AccountMasterFilter get _apiFilter => AccountMasterFilter(
    search: _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim(),
    serviceType: _selectedServiceType?.value,
    isActive: _selectedIsActive,
    isFreeSlot: _selectedIsFreeSlot ? true : null,
    supplyId: _selectedSupply?.id,
    daysRemaining: _selectedDaysRemaining,
    page: 1,
    perPage: 100,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filter = _apiFilter;
      final results = await Future.wait([
        _accountMasterService.stats(filter: filter),
        _accountMasterService.filter(filter: filter),
      ]);

      final statsResp = results[0];
      final filterResp = results[1];

      if (!mounted) return;
      setState(() {
        _stats = statsResp.data as AccountMasterStats?;
        _accounts = (filterResp.data as List<AccountMaster>?) ?? [];
        _selectedAccountIds.removeWhere(
          (id) => !_accounts.any((a) => a.id == id),
        );
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrintStack(
        stackTrace: st,
        label: 'Error loading account master stats: ${e.toString()}',
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch(String value) {
    _loadData();
  }

  void _showFilterBottomSheet() {
    AccountMasterFilterSheet.show(
      context,
      initialFilter: _currentFilter,
      onReset: _resetFilters,
      onApply: (newFilter) {
        setState(() {
          _selectedServiceType = newFilter.serviceType;
          _selectedIsActive = newFilter.isActive;
          _selectedIsFreeSlot = newFilter.isFreeSlot;
          _selectedSupply = newFilter.supply;
          _selectedDaysRemaining = newFilter.daysRemaining;
          _searchController.text = newFilter.search;
        });
        _loadData();
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedIsActive = null;
      _selectedIsFreeSlot = false;
      _selectedSupply = null;
      _selectedDaysRemaining = null;
      _searchController.clear();
      _selectedAccountIds.clear();
    });
    _loadData();
  }

  void _navigateToBatchExpenseCreate() async {
    if (_selectedAccountIds.isEmpty) {
      Toastr.warning('Vui lòng chọn ít nhất 1 tài khoản', context: context);
      return;
    }

    final selectedAccounts = _accounts
        .where((acc) => _selectedAccountIds.contains(acc.id))
        .toList();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AccountMasterBatchExpenseCreateScreen(
          selectedAccounts: selectedAccounts,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedAccountIds.clear();
      });
      _loadData();
    }
  }

  void _removeFilter(VoidCallback update) {
    setState(update);
    _loadData();
  }

  Future<void> _exportExcel() async {
    if (_accounts.isEmpty) {
      Toastr.warning(
        'Không có dữ liệu tài khoản để xuất Excel.',
        context: context,
      );
      return;
    }

    final selectedColumns = await AccountMasterExcelColumnSheet.show(
      context,
      initialSelectedColumns: _selectedExcelColumns,
    );

    if (selectedColumns == null || selectedColumns.isEmpty) return;
    _selectedExcelColumns = selectedColumns;

    setState(() => _isExporting = true);
    try {
      final path = await AccountMasterExcelHelper.exportToExcel(
        _accounts,
        selectedColumns: selectedColumns,
      );
      if (path != null && mounted) {
        Toastr.success('Đã tạo file Excel thành công!', context: context);
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi khi xuất file Excel: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Thống kê tài khoản chính',
      enableSearch: true,
      searchHint: 'Tìm theo tên, ghi chú...',
      searchController: _searchController,
      onSearchChanged: _applySearch,
      onSearchSubmitted: _applySearch,
      actions: [
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
      bottomNavigationBar: _selectedAccountIds.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đã chọn ${_selectedAccountIds.length} tài khoản',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedAccountIds.clear();
                        });
                      },
                      child: const Text('Bỏ chọn'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: _navigateToBatchExpenseCreate,
                      icon: const Icon(Icons.add_card, size: 16),
                      label: const Text('Tạo chi phí'),
                    ),
                  ],
                ),
              ),
            ),
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_hasFilters) _buildActiveFilterChips(cs),
          Expanded(child: _buildBody(scrollController)),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(ColorScheme cs) {
    final chips = <Widget>[
      if (_searchController.text.trim().isNotEmpty)
        _ActiveFilterChip(
          label: 'Tìm: "${_searchController.text.trim()}"',
          onDeleted: () => _removeFilter(() => _searchController.clear()),
        ),
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

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading && _stats == null && _accounts.isEmpty && _error == null) {
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

    if (_error != null && _stats == null && _accounts.isEmpty) {
      final cs = Theme.of(context).colorScheme;
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
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Lỗi: $_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thống kê ở trên (Top statistics section)
              _buildStatsHeader(),
              const SizedBox(height: 16),
              // Header title for table
              Row(
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Danh sách tài khoản chính (${_accounts.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportExcel,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text(
                      'Xuất Excel',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Table section using material_table_view
              _buildTableView(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_stats == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPI Grid
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              title: 'Tổng tài khoản',
              value: '${_stats!.totalAccounts ?? 0}',
              subtitle:
                  'Hoạt động: ${_stats!.activeAccounts ?? 0} | Ngưng: ${_stats!.inactiveAccounts ?? 0}',
              icon: Icons.dns_rounded,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Chi phí tháng',
              value: CurrencyHelper.formatCurrency(
                _stats!.totalMonthlyCost ?? 0,
              ),
              subtitle: 'Tổng định phí hàng tháng',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.purple,
            ),
            _buildStatCard(
              title: 'Thống kê Slot',
              value:
                  '${_stats!.totalActiveSlots ?? 0} / ${_stats!.totalMaxSlots ?? 0}',
              subtitle: 'Còn trống: ${_stats!.totalFreeSlots ?? 0} slot',
              icon: Icons.grid_view_rounded,
              color: Colors.teal,
            ),
            _buildStatCard(
              title: 'Cảnh báo Slot',
              value: '${_stats!.expiringSlotsCount ?? 0} sắp hết',
              subtitle: 'Đã hết hạn: ${_stats!.expiredSlotsCount ?? 0}',
              icon: Icons.warning_amber_rounded,
              color: (_stats!.expiringSlotsCount ?? 0) > 0
                  ? Colors.amber.shade800
                  : cs.onSurfaceVariant,
            ),
          ],
        ),

        // Breakdown by service type (if present)
        if (_stats!.byServiceType != null &&
            _stats!.byServiceType!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Theo loại dịch vụ',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stats!.byServiceType!.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _stats!.byServiceType![index];
                final serviceEnum = enums.AccountMasterServiceType.fromValue(
                  item.serviceType,
                );
                final color = serviceEnum?.color ?? cs.primary;
                final icon = serviceEnum?.icon ?? Icons.layers;
                final label = item.serviceLabel?.isNotEmpty == true
                    ? item.serviceLabel!
                    : (serviceEnum?.label ?? item.serviceType ?? 'Khác');

                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.totalAccounts ?? 0} TK  ·  Active: ${item.activeAccounts ?? 0}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Slot: ${item.totalActiveSlots ?? 0}/${item.totalMaxSlots ?? 0} (Trống: ${item.totalFreeSlots ?? 0})',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView() {
    if (_accounts.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Không có tài khoản chính nào'),
      );
    }

    final cs = Theme.of(context).colorScheme;

    final columns = const [
      TableColumn(width: 48, freezePriority: 2), // Checkbox column
      TableColumn(width: 180, freezePriority: 1), // username
      TableColumn(width: 130), // service_type
      TableColumn(width: 140), // supply name
      TableColumn(width: 100), // max slot
      TableColumn(width: 120), // pay date
      TableColumn(width: 140), // monthly cost
      TableColumn(width: 130), // CP tháng này
      TableColumn(width: 140), // created at
      TableColumn(width: 140), // updated at
    ];

    final headers = [
      '', // Checkbox header
      'Username',
      'Loại dịch vụ',
      'Nhà cung cấp',
      'Max Slot',
      'Ngày trả phí',
      'Chi phí hàng tháng',
      'CP tháng này',
      'Ngày tạo',
      'Ngày cập nhật',
    ];

    return Container(
      height: 480,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: TableView.builder(
        columns: columns,
        rowCount: _accounts.length,
        rowHeight: 44,
        headerBuilder: (context, contentBuilder) {
          final isAllSelected = _accounts.isNotEmpty &&
              _selectedAccountIds.length == _accounts.length;
          final isSomeSelected = _selectedAccountIds.isNotEmpty &&
              _selectedAccountIds.length < _accounts.length;

          return Container(
            color: cs.surfaceContainerHigh,
            child: contentBuilder(context, (context, columnIndex) {
              if (columnIndex == 0) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.8),
                      ),
                      right: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Checkbox(
                    tristate: true,
                    value: isAllSelected
                        ? true
                        : (isSomeSelected ? null : false),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedAccountIds =
                              _accounts.map((a) => a.id).toSet();
                        } else {
                          _selectedAccountIds.clear();
                        }
                      });
                    },
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.8),
                    ),
                    right: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Text(
                  headers[columnIndex],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: cs.onSurface,
                  ),
                ),
              );
            }),
          );
        },
        rowBuilder: (context, rowIndex, contentBuilder) {
          final account = _accounts[rowIndex];
          final isEven = rowIndex % 2 == 0;
          final isSelected = _selectedAccountIds.contains(account.id);

          return Container(
            color: isSelected
                ? cs.primaryContainer.withValues(alpha: 0.25)
                : (isEven
                    ? cs.surface
                    : cs.surfaceContainerLow.withValues(alpha: 0.5)),
            child: contentBuilder(context, (context, columnIndex) {
              if (columnIndex == 0) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      right: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedAccountIds.add(account.id);
                        } else {
                          _selectedAccountIds.remove(account.id);
                        }
                      });
                    },
                  ),
                );
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AccountMasterDetailScreen(accountMaster: account),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      right: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: _buildTableCell(account, columnIndex - 1, cs),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTableCell(
    AccountMaster account,
    int columnIndex,
    ColorScheme cs,
  ) {
    switch (columnIndex) {
      case 0: // username
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: account.isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                account.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 1: // service_type
        final serviceEnum = enums.AccountMasterServiceType.fromValue(
          account.serviceType,
        );
        final label = serviceEnum?.label ?? account.serviceType;
        return Text(
          label.isNotEmpty ? label : '-',
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 2: // supply name
        return Text(
          account.supply?.name ?? '-',
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 3: // max slot
        final count = account.slotsCount ?? account.slots?.length ?? 0;
        return Text(
          '$count / ${account.maxSlots}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        );
      case 4: // pay date
        return Text(
          DateHelper.formatDateShort(account.paymentDate),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        );
      case 5: // monthly cost
        return Text(
          account.monthlyCost != null
              ? CurrencyHelper.formatCurrency(account.monthlyCost!)
              : '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        );
      case 6: // CP tháng này (hasExpenseThisMonth)
        if (account.hasExpenseThisMonth == true) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Đã phát sinh',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        } else if (account.hasExpenseThisMonth == false) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.remove_circle_outline,
                  size: 12,
                  color: Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  'Chưa phát sinh',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Text(
            '-',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          );
        }
      case 7: // created at
        return Text(
          DateHelper.formatDateTimeShort(account.createdAt),
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        );
      case 8: // updated at
        return Text(
          DateHelper.formatDateTimeShort(account.updatedAt),
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer),
      ),
      onDeleted: onDeleted,
      deleteIconColor: cs.onSecondaryContainer,
      backgroundColor: cs.secondaryContainer,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(left: 8, right: 2),
    );
  }
}
