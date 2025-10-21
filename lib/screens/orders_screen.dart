import 'package:fcode_pos/screens/order_create_screen.dart';
import 'package:fcode_pos/ui/components/order_list_component.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

/// Màn hình danh sách đơn hàng
/// Sử dụng OrderListComponent để hiển thị danh sách với các bộ lọc
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = 'complete';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _perPage = 20;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: OrderListComponent(
              fromDate: _fromDate,
              toDate: _toDate,
              status: _selectedStatus,
              perPage: _perPage,
              onOrderTap: (order) {
                // Xử lý khi click vào đơn hàng
                Toastr.show('Đã chọn đơn hàng #${order.id}');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const OrderCreateScreen(),
              fullscreenDialog: true,
            ),
          );

          if (created == true && mounted) {
            Toastr.success('Đã tạo đơn hàng mới');
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo đơn hàng'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filter trạng thái
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Trạng thái: $_selectedStatus'),
                onSelected: (bool selected) {
                  _showStatusFilterDialog();
                },
              ),
            ),

            // Filter ngày bắt đầu
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  'Từ: ${_fromDate?.toString().split(' ')[0] ?? 'N/A'}',
                ),
                onSelected: (bool selected) {
                  _pickFromDate();
                },
              ),
            ),

            // Filter ngày kết thúc
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  'Đến: ${_toDate?.toString().split(' ')[0] ?? 'N/A'}',
                ),
                onSelected: (bool selected) {
                  _pickToDate();
                },
              ),
            ),

            // Reset filters
            ActionChip(
              label: const Text('Reset'),
              onPressed: () {
                setState(() {
                  _selectedStatus = 'new';
                  _fromDate = DateTime.now().subtract(const Duration(days: 7));
                  _toDate = DateTime.now();
                  _perPage = 20;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn trạng thái'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusOption('new', '🔵 Mới'),
                _buildStatusOption('pending', '⏳ Chờ xử lý'),
                _buildStatusOption('completed', '✅ Hoàn thành'),
                _buildStatusOption('cancelled', '❌ Hủy'),
                _buildStatusOption('renew', '🔄 Gia hạn'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(String value, String label) {
    return ListTile(
      title: Text(label),
      trailing: _selectedStatus == value ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _toDate = picked;
      });
    }
  }
}
