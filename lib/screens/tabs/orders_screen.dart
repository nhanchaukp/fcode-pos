import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/order/order_filter_provider.dart';
import 'package:fcode_pos/providers/order/order_list_provider.dart';
import 'package:fcode_pos/screens/global_search_screen.dart';
import 'package:fcode_pos/screens/order/order_create_screen.dart';
import 'package:fcode_pos/ui/components/dropdown/customer_dropdown.dart';
import 'package:fcode_pos/ui/components/order_list_component.dart'
    show OrderListComponent, OrderListViewMode;
import 'package:fcode_pos/ui/components/dropdown/order_status_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  OrderListViewMode _orderListViewMode = OrderListViewMode.full;

  Route<T> _slideUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(orderFilterProvider);
    final orderListAsync = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _orderListViewMode == OrderListViewMode.full
                  ? Icons.view_agenda_outlined
                  : Icons.view_list,
            ),
            onPressed: () {
              setState(() {
                _orderListViewMode =
                    _orderListViewMode == OrderListViewMode.full
                    ? OrderListViewMode.compact
                    : OrderListViewMode.full;
              });
            },
            tooltip: _orderListViewMode == OrderListViewMode.full
                ? 'Xem rút gọn'
                : 'Xem đầy đủ',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible: filter.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(orderListProvider);
          },
          child: orderListAsync.when(
            data: (state) => OrderListComponent(
              orders: state.orders,
              isLoading: false,
              error: null,
              currentPage: state.pagination?.currentPage ?? 1,
              totalPages: state.pagination?.lastPage ?? 1,
              viewMode: _orderListViewMode,
              orderSummary: state.summary,
              isLoadingSummary: false,
              onPageChanged: (page) {
                ref.read(orderFilterProvider.notifier).state = filter.copyWith(
                  page: page,
                );
              },
              onRetry: () => ref.invalidate(orderListProvider),
            ),
            loading: () => OrderListComponent(
              orders: const [],
              isLoading: true,
              error: null,
              currentPage: filter.page,
              totalPages: 1,
              viewMode: _orderListViewMode,
              orderSummary: null,
              isLoadingSummary: true,
              onPageChanged: (_) {},
              onRetry: () {},
            ),
            error: (error, _) => OrderListComponent(
              orders: const [],
              isLoading: false,
              error: error.toString(),
              currentPage: filter.page,
              totalPages: 1,
              viewMode: _orderListViewMode,
              orderSummary: null,
              isLoadingSummary: false,
              onPageChanged: (_) {},
              onRetry: () => ref.invalidate(orderListProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'search',
            shape: const CircleBorder(),
            onPressed: () {
              Navigator.push(
                context,
                _slideUpRoute(const GlobalSearchScreen()),
              );
            },
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            shape: const CircleBorder(),
            onPressed: () {
              Navigator.push<bool>(
                context,
                _slideUpRoute(const OrderCreateScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final filter = ref.read(orderFilterProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OrderFilterSheet(
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        selectedStatus: filter.status,
        selectedUser: filter.user,
        onApply: (from, to, status, user) {
          ref.read(orderFilterProvider.notifier).state = OrderFilter(
            fromDate: from,
            toDate: to,
            status: status,
            user: user,
            page: 1,
          );
          Navigator.pop(context);
        },
        onReset: () {
          final now = DateTime.now();
          ref.read(orderFilterProvider.notifier).state = OrderFilter(
            fromDate: now,
            toDate: now,
            status: OrderStatus.all,
            page: 1,
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({
    required this.fromDate,
    required this.toDate,
    required this.selectedStatus,
    required this.selectedUser,
    required this.onApply,
    required this.onReset,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final OrderStatus? selectedStatus;
  final User? selectedUser;
  final void Function(
    DateTime from,
    DateTime to,
    OrderStatus? status,
    User? user,
  )
  onApply;
  final VoidCallback onReset;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late DateTime? _localFrom;
  late DateTime? _localTo;
  late OrderStatus? _localStatus;
  late User? _localUser;

  @override
  void initState() {
    super.initState();
    _localFrom = widget.fromDate;
    _localTo = widget.toDate;
    _localStatus = widget.selectedStatus;
    _localUser = widget.selectedUser;
  }

  String? _getActiveQuickDateRange() {
    if (_localFrom == null || _localTo == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(_localFrom!.year, _localFrom!.month, _localFrom!.day);
    final to = DateTime(_localTo!.year, _localTo!.month, _localTo!.day);
    if (from == today && to == today) return 'today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (from == yesterday && to == today) return 'yesterday';
    if (to == today && from == today.subtract(const Duration(days: 7))) {
      return '7days';
    }
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    if (to == today && from == oneMonthAgo) return '1month';
    return null;
  }

  void _setQuickDateRange(String type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case 'today':
          _localFrom = DateTime(now.year, now.month, now.day);
          _localTo = now;
          break;
        case 'yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          _localFrom = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _localTo = DateTime(now.year, now.month, now.day);
          break;
        case '7days':
          _localFrom = now.subtract(const Duration(days: 7));
          _localTo = now;
          break;
        case '1month':
          _localFrom = DateTime(now.year, now.month - 1, now.day);
          _localTo = now;
          break;
        default:
          _localFrom = DateTime(now.year, now.month, now.day);
          _localTo = now;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khoảng ngày',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickDateChip('Hôm nay', 'today'),
                const SizedBox(width: 8),
                _buildQuickDateChip('Hôm qua', 'yesterday'),
                const SizedBox(width: 8),
                _buildQuickDateChip('7 ngày', '7days'),
                const SizedBox(width: 8),
                _buildQuickDateChip('1 tháng', '1month'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _localFrom != null && _localTo != null
                          ? DateTimeRange(start: _localFrom!, end: _localTo!)
                          : null,
                    );
                    if (picked != null && mounted) {
                      setState(() {
                        _localFrom = picked.start;
                        _localTo = picked.end;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Khoảng ngày',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _localFrom != null && _localTo != null
                          ? '${DateFormat('dd/MM/yyyy').format(_localFrom!)} - ${DateFormat('dd/MM/yyyy').format(_localTo!)}'
                          : 'Chọn khoảng ngày',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OrderStatusDropdown(
            initialValue: _localStatus,
            onChanged: (value) {
              setState(() => _localStatus = value);
            },
            includeAllOption: true,
            required: false,
            hintText: 'Chọn trạng thái',
          ),
          const SizedBox(height: 18),
          CustomerSearchDropdown(
            selectedUser: _localUser,
            onChanged: (user) {
              setState(() => _localUser = user);
            },
            isRequired: false,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onReset,
                  child: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final from = _localFrom ?? DateTime.now();
                    final to = _localTo ?? DateTime.now();
                    widget.onApply(from, to, _localStatus, _localUser);
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, String type) {
    final isSelected = _getActiveQuickDateRange() == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setQuickDateRange(type),
    );
  }
}
