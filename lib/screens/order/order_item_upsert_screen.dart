import 'package:flutter/material.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/account_form_input.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/dropdown/account_slot_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/product_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/supply_dropdown.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/ui/components/note_form_field.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:fcode_pos/utils/functions.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';

/// Màn hình thêm mới hoặc cập nhật sản phẩm trong đơn hàng ([OrderItem]).
///
/// Hỗ trợ 2 chế độ sử dụng:
/// 1. **Trực tiếp với [orderId]** (khi xem chi tiết đơn hàng): Tự động gọi API `upsertItems` / `deleteItem` và trả về [Order] mới nhất.
/// 2. **Form cục bộ** (khi tạo đơn hàng mới chưa có `orderId`): Cập nhật [OrderItemFormData] và trả về qua `Navigator.pop`.
class OrderItemUpsertScreen extends StatefulWidget {
  /// ID đơn hàng (truyền khi cập nhật sản phẩm trong đơn hàng đã tạo)
  final int? orderId;

  /// Dữ liệu OrderItem hiện tại (khi cập nhật sản phẩm đã lưu)
  final OrderItem? orderItem;

  /// Dữ liệu form sẵn có (khi tạo/sửa sản phẩm trong màn hình tạo đơn hàng)
  final OrderItemFormData? itemData;

  /// Callback khi thao tác thành công (trả về Order cập nhật)
  final void Function(Order updatedOrder)? onSuccess;

  const OrderItemUpsertScreen({
    super.key,
    this.orderId,
    this.orderItem,
    this.itemData,
    this.onSuccess,
  });

  @override
  State<OrderItemUpsertScreen> createState() => _OrderItemUpsertScreenState();
}

class _OrderItemUpsertScreenState extends State<OrderItemUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productSupplyService = ProductSupplyService();
  final _orderService = OrderService();

  late final OrderItemFormData _itemData;
  late final TextEditingController _expiredAtController;
  late final TextEditingController _noteController;
  late final TextEditingController _quantityController;

  bool _isProcessing = false;
  bool _isLoadingBestPrice = false;

  bool get isAddMode => widget.orderItem == null && widget.itemData == null;
  bool get canDelete =>
      widget.orderId != null && widget.orderItem?.id != null;

  @override
  void initState() {
    super.initState();

    if (widget.itemData != null) {
      _itemData = widget.itemData!;
    } else if (widget.orderItem != null) {
      _itemData = OrderItemFormData.fromOrderItem(widget.orderItem);
    } else {
      _itemData = OrderItemFormData();
    }

    _quantityController = TextEditingController(
      text: _itemData.quantity.toString(),
    );
    _quantityController.addListener(() {
      _itemData.quantity = int.tryParse(_quantityController.text) ?? 1;
    });

    _expiredAtController = TextEditingController(
      text: _formatExpiredAt(_itemData.expiredAt),
    );

    _noteController = TextEditingController(text: _itemData.note ?? '');
    _noteController.addListener(() {
      var text = _noteController.text;
      if (text.contains('|')) {
        final transformed = text.replaceAll('|', '\n');
        if (transformed != text) {
          _noteController.value = TextEditingValue(
            text: transformed,
            selection: TextSelection.collapsed(offset: transformed.length),
          );
          text = transformed;
        }
      }
      _itemData.note = text.isEmpty ? null : text;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _expiredAtController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatExpiredAt(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBestPrice({int? supplyId}) async {
    if (_itemData.product == null) return;

    setState(() => _isLoadingBestPrice = true);

    try {
      final bestPriceResult = await _productSupplyService.bestPrice(
        _itemData.product!.id,
        supplyId: supplyId,
      );

      if (!mounted) return;

      if (bestPriceResult.data != null) {
        final bestPrice = bestPriceResult.data!;
        setState(() {
          _itemData.supply ??= bestPrice.supply;
          _itemData.priceSupply = bestPrice.price;
          _itemData.priceSupplyController.text = bestPrice.price.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading best price: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBestPrice = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initialDate = _itemData.expiredAt ?? now;
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365 * 5));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi'),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (!mounted) return;

    final hour = pickedTime?.hour ?? initialDate.hour;
    final minute = pickedTime?.minute ?? initialDate.minute;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      hour,
      minute,
    );

    setState(() {
      _itemData.expiredAt = combined;
      _expiredAtController.text = _formatExpiredAt(combined);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Sync numerical controller values
      _itemData.price = _itemData.priceController.moneyValue;
      _itemData.priceSupply = _itemData.priceSupplyController.moneyValue;

      if (widget.orderId != null) {
        // API mode: Save to existing order
        final itemToSave = _itemData.toOrderItem(widget.orderId);
        final response = await _orderService.upsertItems(
          widget.orderId!,
          OrderUpsertItemsData(items: [itemToSave]),
        );

        final updatedOrder = response.data;
        if (!mounted) return;

        Toastr.success(
          isAddMode
              ? 'Thêm sản phẩm thành công'
              : 'Cập nhật sản phẩm thành công',
          context: context,
        );

        if (updatedOrder != null) {
          widget.onSuccess?.call(updatedOrder);
        }
        Navigator.of(context).pop(updatedOrder);
      } else {
        // Local form mode (e.g. OrderCreateScreen)
        if (!mounted) return;
        Navigator.of(context).pop(_itemData);
      }
    } catch (e) {
      debugPrint('Error saving order item: $e');
      if (mounted) {
        Toastr.error('Lỗi: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa sản phẩm này khỏi đơn hàng?',
        ),
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

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final response = await _orderService.deleteItem(
        widget.orderId!,
        widget.orderItem!.id!,
      );
      final updatedOrder = response.data;

      if (!mounted) return;

      Toastr.success('Xóa sản phẩm thành công', context: context);
      if (updatedOrder != null) {
        widget.onSuccess?.call(updatedOrder);
      }
      Navigator.of(context).pop(updatedOrder);
    } catch (e) {
      debugPrint('Error deleting order item: $e');
      if (mounted) {
        Toastr.error('Lỗi: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: isAddMode ? 'Thêm sản phẩm' : 'Cập nhật sản phẩm',
      actions: [
        if (canDelete)
          IconButton(
            tooltip: 'Xóa sản phẩm',
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _isProcessing ? null : _handleDelete,
          ),
        IconButton(
          tooltip: isAddMode ? 'Thêm' : 'Lưu',
          icon: LoadingIcon(
            icon: Icons.check,
            loading: _isProcessing,
          ),
          onPressed: _isProcessing ? null : _handleSave,
        ),
      ],
      body: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductSearchDropdown(
                selectedProduct: _itemData.product,
                isRequired: true,
                onChanged: (product) async {
                  setState(() {
                    _itemData.product = product;
                    if (product != null) {
                      _itemData.price = product.priceSale ?? product.price;
                      _itemData.priceController.text =
                          _itemData.price.toString();

                      if (product.expiryMonth != null && product.expiryMonth! > 0) {
                        _itemData.expiredAt = addMonths(
                          DateTime.now(),
                          product.expiryMonth!,
                        );
                        _expiredAtController.text =
                            _formatExpiredAt(_itemData.expiredAt);
                      }
                    }
                  });
                  if (product != null) {
                    await _loadBestPrice();
                  }
                },
                validator: (_) {
                  if (_itemData.product == null) {
                    return 'Vui lòng chọn sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SupplyDropdown(
                selectedSupply: _itemData.supply,
                isRequired: true,
                onChanged: (supply) async {
                  setState(() {
                    _itemData.supply = supply;
                  });
                  if (supply != null) {
                    await _loadBestPrice(supplyId: supply.id);
                  }
                },
                validator: (_) {
                  if (_itemData.supply == null) {
                    return 'Vui lòng chọn nhà cung cấp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              QuantityInput(
                controller: _quantityController,
                onChanged: (value) {
                  _itemData.quantity = int.tryParse(value) ?? 1;
                },
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty <= 0) {
                    return 'Số lượng phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MoneyFormField(
                      controller: _itemData.priceSupplyController,
                      labelText: 'Giá vốn',
                      hintText: '0',
                      isLoading: _isLoadingBestPrice,
                      onChanged: (value) {
                        _itemData.priceSupply = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoneyFormField(
                      controller: _itemData.priceController,
                      labelText: 'Giá bán',
                      hintText: '0',
                      onChanged: (value) {
                        _itemData.price = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                onTap: _selectDateTime,
                decoration: const InputDecoration(
                  labelText: 'Ngày hết hạn *',
                  hintText: 'Chọn ngày giờ hết hạn',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                controller: _expiredAtController,
                validator: (_) {
                  if (_itemData.expiredAt == null) {
                    return 'Vui lòng chọn ngày hết hạn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              NoteFormField(
                controller: _noteController,
                labelText: 'Ghi chú',
                hintText: 'Nhập ghi chú cho sản phẩm này',
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              AccountSlotDropdown(
                selectedSlot: _itemData.accountSlot,
                labelText: 'Account slot',
                onChanged: (slot) {
                  setState(() {
                    _itemData.accountSlot = slot;
                    final slotSupply = slot?.accountMaster?.supply;
                    if (_itemData.supply == null && slotSupply != null) {
                      _itemData.supply = slotSupply;
                    }
                    final maxSlots = slot?.accountMaster?.maxSlots;
                    final monthlyCost = slot?.accountMaster?.monthlyCost;
                    final hasPriceSupply =
                        _itemData.priceSupplyController.moneyValue > 0;
                    if (!hasPriceSupply &&
                        maxSlots != null &&
                        maxSlots > 0 &&
                        monthlyCost != null) {
                      _itemData.priceSupply = monthlyCost ~/ maxSlots;
                      _itemData.priceSupplyController.text =
                          _itemData.priceSupply.toString();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              AccountFormInput(
                key: ValueKey('account-${_itemData.account?.hashCode ?? 0}'),
                initialAccount: _itemData.account,
                onAccountChanged: (accountData) {
                  _itemData.account = accountData;
                },
              ),
              const SizedBox(height: 28),
              _buildActionButtons(colorScheme),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Khối nút hành động ở cuối form
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Hủy'),
          ),
        ),
        if (canDelete) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isProcessing ? null : _handleDelete,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Xóa'),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          flex: canDelete ? 1 : 2,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _handleSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
            icon: LoadingIcon(
              icon: Icons.check,
              loading: _isProcessing,
            ),
            label: Text(isAddMode ? 'Thêm' : 'Lưu'),
          ),
        ),
      ],
    );
  }
}
