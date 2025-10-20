import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/order_create_screen.dart';
import 'package:fcode_pos/ui/components/customer_search_dropdown.dart';
import 'package:fcode_pos/ui/components/global_order_search.dart';
import 'package:fcode_pos/ui/components/order_list_component.dart';
import 'package:fcode_pos/ui/components/order_status_dropdown.dart';
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

  // Key for refreshing order list
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now();
    _toDate = DateTime.now();
    _selectedStatus = OrderStatus.all;
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
            icon: const Icon(Icons.filter_list_alt),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear progress indicator
            if (_isLoading) const LinearProgressIndicator(),

            // Stats summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng: $_totalItems đơn hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Trang $_currentPage/$_totalPages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // // Stats Cards
            // StatsCards(
            //   cards: const [
            //     StatCard(
            //       title: 'Doanh thu',
            //       value: '1tr2',
            //       subtitle: '5 đơn hoàn tất',
            //       icon: Icons.shopping_bag_outlined,
            //       subtitleColor: Colors.greenAccent,
            //     ),
            //     StatCard(
            //       title: 'Lợi nhuận',
            //       value: '3200 ₫',
            //       subtitle: '+8% so với ha',
            //       icon: Icons.trending_up_outlined,
            //       subtitleColor: Colors.tealAccent,
            //     ),
            //     StatCard(
            //       title: 'Đơn hôm nay',
            //       value: '12',
            //       subtitle: '2 đơn hủy',
            //       icon: Icons.receipt_long_outlined,
            //       subtitleColor: Colors.redAccent,
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: OrderListComponent(
                key: ValueKey(_refreshKey),
                fromDate: _fromDate,
                toDate: _toDate,
                status: _selectedStatus?.value ?? '',
                userId: _selectedUser?.id.toString(),
                currentPage: _currentPage,
                onPaginationChanged: (currentPage, totalPages) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _currentPage = currentPage;
                        _totalPages = totalPages;
                      });
                    }
                  });
                },
                onLoadingChanged: (isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isLoading = isLoading;
                      });
                    }
                  });
                },
                onTotalChanged: (total) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _totalItems = total;
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderCreateScreen()),
          );

          // Refresh list if order was created successfully
          if (result == true && mounted) {
            setState(() {
              // Reset to first page and refresh the order list
              _currentPage = 1;
              _refreshKey++; // Change key to force rebuild OrderListComponent
            });
          }
        },
        tooltip: 'Tạo đơn hàng mới',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                  onPressed: () => Navigator.pop(context),
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
  }
}
