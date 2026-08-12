import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/ui/components/order_item_editor_modal.dart';

class OrderItemUpdateBottomSheet extends StatelessWidget {
  final int orderId;
  final OrderItem? orderItem;
  final void Function(Order updatedOrder)? onSuccess;

  const OrderItemUpdateBottomSheet({
    super.key,
    required this.orderId,
    this.orderItem,
    this.onSuccess,
  });

  bool get isAddMode => orderItem == null;

  @override
  Widget build(BuildContext context) {
    final itemData = OrderItemFormData.fromOrderItem(orderItem);

    return OrderItemEditorModal(
      itemData: itemData,
      title: isAddMode ? 'Thêm sản phẩm' : 'Cập nhật sản phẩm',
      primaryActionLabel: isAddMode ? 'Thêm' : 'Cập nhật',
      secondaryAction: isAddMode
          ? null
          : OrderItemEditorAction(
              label: 'Xóa',
              onPressed: (data) => _handleDelete(context),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
      onPrimaryAction: (data) => _handleUpdate(context, data),
    );
  }

  Future<bool> _handleUpdate(
    BuildContext context,
    OrderItemFormData data,
  ) async {
    try {
      final orderService = OrderService();
      Order? updatedOrder;

      if (isAddMode) {
        // Add new item
        final newItem = data.toOrderItem(0); // orderId will be set by backend
        final response = await orderService.upsertItems(
          orderId,
          OrderUpsertItemsData(items: [newItem]),
        );
        updatedOrder = response.data;
        if (context.mounted) {
          Toastr.success('Thêm sản phẩm thành công');
        }
      } else {
        // Update existing item
        final updatedItem = data.toOrderItem(orderId);
        final response = await orderService.upsertItems(
          orderId,
          OrderUpsertItemsData(items: [updatedItem]),
        );
        updatedOrder = response.data;
        if (context.mounted) {
          Toastr.success('Cập nhật sản phẩm thành công');
        }
      }

      if (updatedOrder != null) {
        onSuccess?.call(updatedOrder);
        if (context.mounted) {
          Navigator.of(context).pop(updatedOrder);
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        Toastr.error('Lỗi: $e');
      }
      return false;
    }
  }

  Future<bool> _handleDelete(BuildContext context) async {
    if (orderItem?.id == null) return false;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      final orderService = OrderService();
      final response = await orderService.deleteItem(orderId, orderItem!.id!);
      final updatedOrder = response.data;

      if (context.mounted) {
        Toastr.success('Xóa sản phẩm thành công');
        if (updatedOrder != null) {
          onSuccess?.call(updatedOrder);
          Navigator.of(context).pop(updatedOrder);
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        Toastr.error('Lỗi: $e');
      }
      return false;
    }
  }
}
