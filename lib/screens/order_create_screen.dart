import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/customer_search_dropdown.dart';
import 'package:fcode_pos/ui/components/order_item_editor_modal.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _noteController = TextEditingController();

  User? _selectedUser;
  bool _isLoading = false;
  final List<OrderItemFormData> _orderItems = [];

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

      await _orderService.create(newOrder);
      if (!mounted) return;

      Toastr.success('Tạo đơn hàng thành công');
      Navigator.of(context).pop(true);
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tạo đơn hàng'), elevation: 0),
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
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin đơn hàng',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCustomerField(),
            const SizedBox(height: 16),
            _buildNoteField(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sản phẩm (${_orderItems.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _handleAddItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orderItems.isEmpty)
              _buildEmptyItemsState()
            else
              Column(
                children: List.generate(
                  _orderItems.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _orderItems.length - 1 ? 0 : 12,
                    ),
                    child: _buildOrderItemRow(index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
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
      borderRadius: BorderRadius.circular(12),
      onTap: () => _handleEditItem(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
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

    if (result == true) {
      setState(() {
        _orderItems.add(newItem);
      });
    } else {
      newItem.dispose();
    }
  }

  Future<void> _handleEditItem(int index) async {
    final item = _orderItems[index];
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
      onUserSelected: (user) {
        setState(() => _selectedUser = user);
      },
      onUserCleared: () {
        setState(() => _selectedUser = null);
      },
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
                  : const Text('Tạo đơn hàng'),
            ),
          ),
        ],
      ),
    );
  }
}
