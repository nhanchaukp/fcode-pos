import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/order_create_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/customer_search_dropdown.dart';
import 'package:fcode_pos/ui/components/global_order_search.dart';
import 'package:fcode_pos/ui/components/order_list_component.dart';
import 'package:fcode_pos/ui/components/order_status_dropdown.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
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
  int _totalItems = 0;
  bool _isLoading = false;

  // Stats state
  OrderStats? _stats;
  bool _isLoadingStats = false;

  // Orders state
  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  late OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _fromDate = DateTime.now();
    _toDate = DateTime.now();
    _selectedStatus = OrderStatus.all;
    _loadStats();
    _loadOrders();
  }

  Future<void> _loadStats() async {
    if (_fromDate == null || _toDate == null) return;

    try {
      final response = await _orderService.stats(_fromDate!, _toDate!);

      if (mounted) {
        setState(() {
          _stats = response.data;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      Toastr.error('Lỗi tải thống kê đơn hàng.');
    }
  }

  Future<void> _loadOrders({int? page}) async {
    if (_fromDate == null || _toDate == null) return;

    final targetPage = page ?? _currentPage;

    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
      _isLoading = true;
    });

    try {
      final response = await _orderService.list(
        _fromDate!,
        _toDate!,
        page: targetPage,
        perPage: 20,
        status: _selectedStatus?.value ?? '',
        userId: _selectedUser?.id.toString() ?? '',
      );

      if (mounted) {
        final pagination = response.data?.pagination;
        setState(() {
          _orders = response.data?.items ?? [];
          _currentPage = pagination?.currentPage ?? 1;
          _totalPages = pagination?.lastPage ?? 1;
          _totalItems = pagination?.total ?? 0;
          _isLoadingOrders = false;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Error loading orders: $e');
      if (mounted) {
        setState(() {
          _ordersError = e.toString();
          _isLoadingOrders = false;
          _isLoading = false;
        });
      }
    }
  }

  void _setQuickDateRange(String range) {
    final now = DateTime.now();
    setState(() {
      switch (range) {
        case 'today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = now;
          break;
        case 'yesterday':
          final yesterday = now.subtract(Duration(days: 1));
          _fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _toDate = DateTime(now.year, now.month, now.day);
          break;
        case '7days':
          _fromDate = now.subtract(Duration(days: 7));
          _toDate = now;
          break;
        case '1month':
          _fromDate = DateTime(now.year, now.month - 1, now.day);
          _toDate = now;
          break;
      }
    });
    _loadStats(); // Reload stats when date range changes
    _loadOrders(page: 1); // Reload orders when date range changes
  }

  Future<void> _refreshAll() async {
    // Reload stats and orders
    await Future.wait([_loadStats(), _loadOrders(page: 1)]);
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showGlobalOrderSearch(context),
            tooltip: 'Tìm kiếm',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: Column(
            children: [
              // Stats cards
              _buildStatsCards(),

              // Orders List
              Expanded(
                child: OrderListComponent(
                  orders: _orders,
                  isLoading: _isLoadingOrders,
                  error: _ordersError,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageChanged: (page) => _loadOrders(page: page),
                  onRetry: () => _loadOrders(),
                ),
              ),
            ],
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
            _loadStats(); // Reload stats after creating new order
            _loadOrders(page: 1); // Reload orders after creating new order
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard(
            'Tổng đơn',
            _stats!.totalOrdersCount.toString(),
            Icons.shopping_cart,
            Colors.blue,
          ),
          _buildStatCard(
            'Đơn hoàn tất',
            _stats!.completeOrderCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            'Tổng doanh thu',
            CurrencyHelper.formatCurrency(_stats!.totalMoney),
            Icons.attach_money,
            Colors.orange,
          ),
          _buildStatCard(
            'Lợi nhuận',
            CurrencyHelper.formatCurrency(_stats!.revenue),
            Icons.trending_up,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
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
          // Header
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text(
          //       'Bộ lọc',
          //       style: TextStyle(
          //         fontSize: 20,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.close),
          //       onPressed: () => Navigator.pop(context),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 8),

          // Ngày lọc
          const Text(
            'Khoảng ngày',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Quick date range buttons
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildQuickDateButton('Hôm nay', 'today'),
              _buildQuickDateButton('Hôm qua', 'yesterday'),
              _buildQuickDateButton('7 ngày', '7days'),
              _buildQuickDateButton('1 tháng', '1month'),
            ],
          ),
          const SizedBox(height: 18),

          // Custom date range
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Từ ngày',
                  _fromDate,
                  (date) => setState(() => _fromDate = date),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateField(
                  'Đến ngày',
                  _toDate,
                  (date) => setState(() => _toDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Trạng thái đơn hàng
          _buildStatusDropdown(),
          const SizedBox(height: 18),

          _buildCustomerSearch(),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    _loadStats(); // Reload stats when filter applied
                    _loadOrders(page: 1); // Reload orders when filter applied
                    Navigator.pop(context);
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

  Widget _buildQuickDateButton(String label, String type) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _setQuickDateRange(type);
      },
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime?) onDateChanged,
  ) {
    return TextFormField(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateChanged(picked);
          setState(() {});
        }
      },
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return OrderStatusDropdown(
      initialValue: _selectedStatus,
      onChanged: (value) {
        setState(() => _selectedStatus = value);
      },
      includeAllOption: true,
      required: false,
      hintText: 'Chọn trạng thái',
    );
  }

  Widget _buildCustomerSearch() {
    return CustomerSearchDropdown(
      selectedUser: _selectedUser,
      onUserSelected: (User user) {
        setState(() => _selectedUser = user);
      },
      onUserCleared: () {
        setState(() => _selectedUser = null);
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _fromDate = DateTime.now().subtract(Duration(days: 7));
      _toDate = DateTime.now();
      _selectedStatus = OrderStatus.all;
      _selectedUser = null;
    });
    _loadStats(); // Reload stats when filters reset
    _loadOrders(page: 1); // Reload orders when filters reset
  }
}
