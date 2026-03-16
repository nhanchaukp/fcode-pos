import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/global_search_screen.dart';
import 'package:fcode_pos/screens/order/order_create_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
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
  // Filter state
  DateTime? _fromDate;
  DateTime? _toDate;
  OrderStatus? _selectedStatus;
  User? _selectedUser;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;

  // View mode: full vs compact
  OrderListViewMode _orderListViewMode = OrderListViewMode.full;

  // Orders state
  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Summary (thống kê) dùng chung bộ lọc với danh sách đơn
  OrderSummary? _orderSummary;
  bool _isLoadingSummary = false;

  late OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _fromDate = DateTime.now();
    _toDate = DateTime.now();
    _selectedStatus = OrderStatus.all;
    _loadOrders();
  }

  Future<void> _loadOrders({int? page}) async {
    if (_fromDate == null || _toDate == null) return;

    final targetPage = page ?? _currentPage;

    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
      _isLoadingSummary = true;
    });

    try {
      final listFuture = _orderService.list(
        fromDate: _fromDate,
        toDate: _toDate,
        page: targetPage,
        perPage: 20,
        status: _selectedStatus?.value ?? '',
        userId: _selectedUser?.id.toString() ?? '',
      );
      final summaryFuture = _orderService.summary(
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus?.value ?? '',
        userId: _selectedUser?.id.toString() ?? '',
        search: '',
      );

      final results = await Future.wait([listFuture, summaryFuture]);
      final listResponse = results[0] as ApiResponse<PaginatedData<Order>>;
      final summaryResponse = results[1] as ApiResponse<OrderSummary>;

      if (mounted) {
        final pagination = listResponse.data?.pagination;
        setState(() {
          _orders = listResponse.data?.items ?? [];
          _currentPage = pagination?.currentPage ?? 1;
          _totalPages = pagination?.lastPage ?? 1;
          _orderSummary = summaryResponse.data;
          _isLoadingOrders = false;
          _isLoadingSummary = false;
        });
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Error loading orders: $e');
      if (mounted) {
        setState(() {
          _ordersError = e.toString();
          _isLoadingOrders = false;
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    // Reload orders
    await _loadOrders(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authProvider).value;

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
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
            tooltip: 'Tìm kiếm',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible:
                  (_selectedStatus != null &&
                      _selectedStatus != OrderStatus.all) ||
                  _selectedUser != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: OrderListComponent(
            orders: _orders,
            isLoading: _isLoadingOrders,
            error: _ordersError,
            currentPage: _currentPage,
            totalPages: _totalPages,
            viewMode: _orderListViewMode,
            orderSummary: _orderSummary,
            isLoadingSummary: _isLoadingSummary,
            onPageChanged: (page) => _loadOrders(page: page),
            onRetry: () => _loadOrders(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const OrderCreateScreen()),
          );

          // Refresh list if order was created successfully
          if (result == true && mounted) {
            _loadOrders(page: 1); // Reload orders after creating new order
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OrderFilterSheet(
        fromDate: _fromDate,
        toDate: _toDate,
        selectedStatus: _selectedStatus,
        selectedUser: _selectedUser,
        onApply: (from, to, status, user) {
          setState(() {
            _fromDate = from;
            _toDate = to;
            _selectedStatus = status;
            _selectedUser = user;
          });
          _loadOrders(page: 1);
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _fromDate = DateTime.now();
            _toDate = DateTime.now();
            _selectedStatus = OrderStatus.all;
            _selectedUser = null;
          });
          _loadOrders(page: 1);
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
    if (to == today && from == today.subtract(const Duration(days: 7)))
      return '7days';
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
