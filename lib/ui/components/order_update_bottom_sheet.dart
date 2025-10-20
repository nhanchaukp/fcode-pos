import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/customer_search_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/ui/components/order_status_dropdown.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class OrderUpdateBottomSheet extends StatefulWidget {
  final Order order;
  final VoidCallback? onSuccess;

  const OrderUpdateBottomSheet({
    required this.order,
    this.onSuccess,
    super.key,
  });

  @override
  State<OrderUpdateBottomSheet> createState() => _OrderUpdateBottomSheetState();
}

class _OrderUpdateBottomSheetState extends State<OrderUpdateBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = AuthService();
  final _totalController = TextEditingController();
  final _noteController = TextEditingController();

  User? _selectedUser;
  enums.OrderStatus? _selectedStatus;
  String? _selectedUtmSource;
  bool _isLoading = false;

  final List<String> _utmSources = ['zalo', 'telegram', 'facebook'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _totalController.text = widget.order.total.toString();
    _noteController.text = widget.order.note ?? '';
    _selectedUser = widget.order.user;
    _selectedStatus = enums.OrderStatus.fromString(widget.order.status);
    _selectedUtmSource = widget.order.utmSource;
  }

  @override
  void dispose() {
    _totalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedOrder = Order(
        id: widget.order.id,
        userId: _selectedUser?.id ?? widget.order.userId,
        total: _totalController.moneyValue,
        status: _selectedStatus?.value ?? widget.order.status,
        type: widget.order.type,
        // refundAmount: widget.order.refundAmount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        utmSource: _selectedUtmSource,
        // user: _selectedUser,
        items: [],
        paymentHistories: [],
        refunds: [],
      );

      await _orderService.update(widget.order.id.toString(), updatedOrder);

      if (!mounted) return;

      SnackBarHelper.success('Cập nhật đơn hàng thành công');

      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      if (!mounted) return;

      SnackBarHelper.error('Cập nhật đơn hàng thất bại. Vui lòng thử lại.');
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCustomerField(),
                const SizedBox(height: 16),
                _buildTotalField(),
                const SizedBox(height: 16),
                _buildStatusField(),
                const SizedBox(height: 16),
                _buildUtmSourceField(),
                const SizedBox(height: 16),
                _buildNoteField(),
                const SizedBox(height: 24),
                _buildActions(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Cập nhật đơn hàng #${widget.order.id}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCustomerField() {
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

  Widget _buildTotalField() {
    return MoneyFormField(
      controller: _totalController,
      labelText: 'Tổng tiền',
      hintText: 'Nhập tổng tiền',
      prefixIcon: const Icon(Icons.attach_money),
      suffixText: 'đ',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập tổng tiền';
        }
        return null;
      },
    );
  }

  Widget _buildStatusField() {
    return OrderStatusDropdown(
      initialValue: _selectedStatus,
      onChanged: (value) {
        setState(() => _selectedStatus = value);
      },
    );
  }

  Widget _buildUtmSourceField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUtmSource,
      decoration: const InputDecoration(
        labelText: 'Nguồn (UTM Source)',
        // prefixIcon: Icon(Icons.source),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Chọn nguồn'),
      items: _utmSources
          .map(
            (source) => DropdownMenuItem(
              value: source,
              child: Row(
                children: [
                  _getUtmSourceIcon(source),
                  const SizedBox(width: 8),
                  Text(source.toUpperCase()),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedUtmSource = value);
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Ghi chú',
        hintText: 'Nhập ghi chú cho đơn hàng',
        // prefixIcon: Icon(Icons.note_alt_outlined),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _isLoading ? null : _handleUpdate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }

  Icon _getUtmSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'zalo':
        return const Icon(Icons.chat, color: Colors.blue);
      case 'telegram':
        return const Icon(Icons.telegram, color: Colors.lightBlue);
      case 'facebook':
        return const Icon(Icons.facebook, color: Colors.indigo);
      default:
        return const Icon(Icons.public);
    }
  }
}
