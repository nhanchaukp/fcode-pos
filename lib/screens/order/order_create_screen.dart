import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/dropdown/customer_dropdown.dart';
import 'package:fcode_pos/ui/components/section_header.dart';
import 'package:fcode_pos/ui/components/order_item_editor_modal.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fcode_pos/providers/order/order_list_provider.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';

class OrderCreateScreen extends ConsumerStatefulWidget {
  /// Đơn hàng gốc dùng để clone (nếu có).
  /// Nếu null thì màn hình hoạt động ở chế độ tạo đơn mới.
  final Order? initialOrder;

  /// Cờ đánh dấu màn hình đang ở chế độ clone đơn.
  /// Chủ yếu dùng để hiển thị tiêu đề, tooltip, text nút.
  final bool isClone;

  const OrderCreateScreen({super.key, this.initialOrder, this.isClone = false});

  @override
  ConsumerState<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends ConsumerState<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _noteController = TextEditingController();

  User? _selectedUser;
  bool _isLoading = false;
  final List<OrderItemFormData> _orderItems = [];

  @override
  void initState() {
    super.initState();

    final order = widget.initialOrder;
    if (order != null) {
      // Giữ nguyên thông tin khách hàng
      _selectedUser = order.user;

      // Ghi chú đơn
      _noteController.text = order.note ?? '';

      // Clone các item: giữ sản phẩm, nhà cung cấp, giá, số lượng, ghi chú.
      // Không mang theo id, account, accountSlot, expiredAt để tránh ảnh hưởng dữ liệu cũ.
      for (final item in order.items) {
        final formData = OrderItemFormData(
          product: item.product,
          supply: item.supply,
          quantity: item.quantity,
          price: item.price,
          priceSupply: item.priceSupply,
          note: item.note,
        );
        _orderItems.add(formData);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final item in _orderItems) {
      item.dispose();
    }
    super.dispose();
  }

  int _calculateTotal() {
    return _orderItems.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_orderItems.isEmpty) {
      Toastr.error('Vui lòng thêm ít nhất một sản phẩm');
      return;
    }

    for (int i = 0; i < _orderItems.length; i++) {
      final item = _orderItems[i];
      if (item.product == null) {
        Toastr.error('Vui lòng chọn sản phẩm cho dòng ${i + 1}');
        return;
      }
      if (item.supply == null) {
        Toastr.error('Vui lòng chọn nhà cung cấp cho dòng ${i + 1}');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final items = _orderItems.map((item) => item.toOrderItem(0)).toList();
      final newOrder = Order(
        id: 0,
        userId: _selectedUser?.id ?? 0,
        total: _calculateTotal(),
        status: enums.OrderStatus.new_.value,
        type: 'new',
        note: _noteController.text.isEmpty ? null : _noteController.text,
        utmSource: null,
        items: items,
        paymentHistories: const [],
        refunds: const [],
      );

      final response = await _orderService.create(newOrder);
      if (!mounted) return;

      final createdOrder = response.data;

      if (createdOrder != null) {
        ref.read(orderListProvider.notifier).addOrder(createdOrder);
      }

      Toastr.success(
        widget.isClone
            ? 'Clone đơn hàng thành công'
            : 'Tạo đơn hàng thành công',
      );

      if (createdOrder != null && createdOrder.id != 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                OrderDetailScreen(orderId: createdOrder.id.toString()),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      if (mounted) {
        Toastr.error('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isClone ? 'Clone đơn hàng' : 'Tạo đơn hàng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _handleCreate,
            tooltip: widget.isClone ? 'Tạo đơn clone' : 'Tạo đơn',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOrderItemsSection(),
                  const SizedBox(height: 16),
                  _buildSummarySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Thông tin đơn hàng',
          ),
          const SizedBox(height: 12),
          _buildCustomerField(),
          const SizedBox(height: 12),
          _buildNoteField(),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.shopping_cart_outlined,
            title: 'Sản phẩm (${_orderItems.length})',
            action: FilledButton.icon(
              onPressed: _handleAddItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ),
          const SizedBox(height: 8),
          if (_orderItems.isEmpty)
            _buildEmptyItemsState()
          else
            Column(
              children: List.generate(
                _orderItems.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _orderItems.length - 1 ? 0 : 8,
                  ),
                  child: _buildOrderItemRow(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có sản phẩm trong đơn',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm sản phẩm để tính toán giá trị đơn hàng.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(int index) {
    final item = _orderItems[index];
    final productName = item.product?.name ?? 'Chưa chọn sản phẩm';
    final priceLabel = CurrencyHelper.formatCurrency(item.price);
    final totalLabel = CurrencyHelper.formatCurrency(
      item.price * item.quantity,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _handleEditItem(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Tên sản phẩm full width
            Text(
              productName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Dòng 2: Số lượng x Giá | Tổng tiền | Nút xóa
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' x '),
                        TextSpan(
                          text: priceLabel,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _removeOrderItem(index),
                  icon: const Icon(Icons.close, size: 20),
                  color: Theme.of(context).colorScheme.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddItem() async {
    final newItem = OrderItemFormData();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => OrderItemEditorModal(
        itemData: newItem,
        title: 'Thêm sản phẩm',
        primaryActionLabel: 'Thêm',
        onPrimaryAction: (data) async {
          // Just validate and close, actual adding is done below
          return true;
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _orderItems.add(newItem);
      });
    } else {
      // Delay dispose to ensure modal animation completes
      await Future.delayed(const Duration(milliseconds: 300));
      newItem.dispose();
    }
  }

  Future<void> _handleEditItem(int index) async {
    final item = _orderItems[index];
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => OrderItemEditorModal(
        itemData: item,
        title: 'Chỉnh sửa sản phẩm',
        primaryActionLabel: 'Lưu',
        onPrimaryAction: (data) async {
          // Just validate and close, data is already updated
          return true;
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems[index].dispose();
      _orderItems.removeAt(index);
    });
  }

  Widget _buildCustomerField() {
    return CustomerSearchDropdown(
      selectedUser: _selectedUser,
      onChanged: (user) {
        setState(() => _selectedUser = user);
      },
      isRequired: true,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Ghi chú đơn hàng',
        hintText: 'Nhập ghi chú cho đơn hàng',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateTotal();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding * 0.4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyHelper.formatCurrency(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : _handleCreate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.isClone ? 'Tạo đơn clone' : 'Tạo đơn hàng'),
            ),
          ),
        ],
      ),
    );
  }
}
