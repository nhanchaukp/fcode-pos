import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/account_form_input.dart';
import 'package:fcode_pos/ui/components/account_slot_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/ui/components/dropdown/product_dropdown.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:fcode_pos/ui/components/dropdown/supply_dropdown.dart';
import 'package:fcode_pos/utils/functions.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

/// A reusable modal for editing order item details.
/// Can be used for both creating new items and updating existing ones.
class OrderItemEditorModal extends StatefulWidget {
  /// The item form data to edit
  final OrderItemFormData itemData;

  /// Title displayed at the top of the modal
  final String title;

  /// Label for the primary action button (e.g., "Lưu", "Cập nhật", "Thêm")
  final String primaryActionLabel;

  /// Called when primary action button is pressed and form is valid
  final Future<bool> Function(OrderItemFormData data) onPrimaryAction;

  /// Optional secondary action button configuration
  final OrderItemEditorAction? secondaryAction;

  /// Whether to show loading indicator
  final bool showLoading;

  const OrderItemEditorModal({
    super.key,
    required this.itemData,
    required this.title,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryAction,
    this.showLoading = false,
  });

  @override
  State<OrderItemEditorModal> createState() => _OrderItemEditorModalState();
}

class _OrderItemEditorModalState extends State<OrderItemEditorModal> {
  final _formKey = GlobalKey<FormState>();
  final _productSupplyService = ProductSupplyService();
  late final TextEditingController _expiredAtController;

  bool _isLoadingBestPrice = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _expiredAtController = TextEditingController(
      text: _formatExpiredAt(widget.itemData.expiredAt),
    );
  }

  @override
  void dispose() {
    _expiredAtController.dispose();
    super.dispose();
  }

  String _formatExpiredAt(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBestPrice({int? supplyId}) async {
    if (widget.itemData.product == null) return;

    setState(() => _isLoadingBestPrice = true);

    try {
      final bestPriceResult = await _productSupplyService.bestPrice(
        widget.itemData.product!.id,
        supplyId: supplyId,
      );

      if (!mounted) return;

      if (bestPriceResult.data != null) {
        final bestPrice = bestPriceResult.data!;
        setState(() {
          widget.itemData.supply ??= bestPrice.supply;
          widget.itemData.priceSupply = bestPrice.price;
          widget.itemData.priceSupplyController.text = bestPrice.price
              .toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading best price: $e');
      Toastr.error('Không thể tải giá tốt nhất', context: context);
    } finally {
      if (mounted) {
        setState(() => _isLoadingBestPrice = false);
      }
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (widget.itemData.product == null) {
      Toastr.error('Vui lòng chọn sản phẩm', context: context);
      return;
    }
    if (widget.itemData.supply == null) {
      Toastr.error('Vui lòng chọn nhà cung cấp', context: context);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update values from controllers
      widget.itemData.price = widget.itemData.priceController.moneyValue;
      widget.itemData.priceSupply =
          widget.itemData.priceSupplyController.moneyValue;

      final success = await widget.onPrimaryAction(widget.itemData);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error in primary action: $e');
      if (mounted) {
        Toastr.error(e.toString(), context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSecondaryAction() async {
    if (widget.secondaryAction == null) return;

    setState(() => _isProcessing = true);

    try {
      final success = await widget.secondaryAction!.onPressed(widget.itemData);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error in secondary action: $e');
      Toastr.error(e.toString(), context: context);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildProductField(),
                    const SizedBox(height: 16),
                    _buildSupplyField(),
                    const SizedBox(height: 16),
                    _buildQuantityInput(),
                    const SizedBox(height: 16),
                    _buildPriceFields(),
                    const SizedBox(height: 16),
                    _buildExpiredAtField(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    const SizedBox(height: 16),
                    _buildAccountSection(),
                  ],
                ),
              ),
            ),
          ),
          // Fixed action buttons at bottom
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom * 0.3,
            ),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProductField() {
    return ProductSearchDropdown(
      selectedProduct: widget.itemData.product,
      onChanged: (product) async {
        setState(() {
          widget.itemData.product = product;
          if (product != null) {
            widget.itemData.price = product.priceSale ?? product.price;
            widget.itemData.priceController.text = widget.itemData.price
                .toString();

            // Auto-calculate expiredAt based on product.expiryMonth
            if (product.expiryMonth != null && product.expiryMonth! > 0) {
              widget.itemData.expiredAt = addMonths(
                DateTime.now(),
                product.expiryMonth!,
              );
              _expiredAtController.text = _formatExpiredAt(
                widget.itemData.expiredAt,
              );
            }
          }
        });
        if (product != null) {
          await _loadBestPrice();
        }
      },
    );
  }

  Widget _buildSupplyField() {
    return SupplyDropdown(
      selectedSupply: widget.itemData.supply,
      onChanged: (supply) async {
        setState(() {
          widget.itemData.supply = supply;
        });
        if (supply != null && widget.itemData.product != null) {
          await _loadBestPrice(supplyId: supply.id);
        }
      },
    );
  }

  Widget _buildQuantityInput() {
    return QuantityInput(
      initialQuantity: widget.itemData.quantity,
      minQuantity: 1,
      onQuantityChanged: (quantity) {
        setState(() {
          widget.itemData.quantity = quantity;
        });
      },
    );
  }

  Widget _buildPriceFields() {
    return Row(
      children: [
        Expanded(
          child: MoneyFormField(
            controller: widget.itemData.priceSupplyController,
            labelText: 'Giá vốn',
            hintText: '0',
            isLoading: _isLoadingBestPrice,
            onChanged: (value) {
              widget.itemData.priceSupply = value;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MoneyFormField(
            controller: widget.itemData.priceController,
            labelText: 'Giá bán',
            hintText: '0',
            onChanged: (value) {
              widget.itemData.price = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredAtField() {
    return TextFormField(
      readOnly: true,
      onTap: _selectDateTime,
      decoration: const InputDecoration(
        labelText: 'Ngày hết hạn',
        hintText: 'Chọn ngày giờ hết hạn',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      controller: _expiredAtController,
    );
  }

  Future<void> _selectDateTime() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initialDate = widget.itemData.expiredAt ?? now;
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365 * 5));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi'),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      widget.itemData.expiredAt = combined;
      _expiredAtController.text = _formatExpiredAt(combined);
    });
  }

  Widget _buildNoteField() {
    return TextFormField(
      initialValue: widget.itemData.note,
      decoration: const InputDecoration(
        labelText: 'Ghi chú',
        hintText: 'Nhập ghi chú cho sản phẩm này',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 2,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: (value) {
        widget.itemData.note = value.isEmpty ? null : value;
      },
    );
  }

  Widget _buildAccountSection() {
    return ExpansionTile(
      title: const Text(
        'Tài khoản nâng cấp',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      initiallyExpanded: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              AccountFormInput(
                key: ValueKey('account-${widget.itemData.hashCode}'),
                initialAccount: widget.itemData.account,
                onAccountChanged: (accountData) {
                  widget.itemData.account = accountData;
                },
              ),
              const SizedBox(height: 16),
              AccountSlotDropdown(
                selectedSlot: widget.itemData.accountSlot,
                onSlotSelected: (slot) {
                  setState(() {
                    widget.itemData.accountSlot = slot;
                  });
                },
                onSlotCleared: () {
                  setState(() {
                    widget.itemData.accountSlot = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasSecondary = widget.secondaryAction != null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
        if (hasSecondary) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isProcessing ? null : _handleSecondaryAction,
              style: FilledButton.styleFrom(
                backgroundColor: widget.secondaryAction!.backgroundColor,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.secondaryAction!.label),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isProcessing ? null : _handlePrimaryAction,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.primaryActionLabel),
          ),
        ),
      ],
    );
  }
}

/// Configuration for an action button in the order item editor
class OrderItemEditorAction {
  /// Button label
  final String label;

  /// Callback when button is pressed
  /// Should return true if successful, false otherwise
  final Future<bool> Function(OrderItemFormData data) onPressed;

  /// Optional background color for the button
  final Color? backgroundColor;

  const OrderItemEditorAction({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });
}

/// Data class for order item form
class OrderItemFormData {
  int? id;
  Product? product;
  Supply? supply;
  int quantity;
  int price;
  int priceSupply;
  Map<String, dynamic>? account;
  AccountSlot? accountSlot;
  String? note;
  DateTime? expiredAt;

  final TextEditingController priceSupplyController;
  final TextEditingController priceController;

  OrderItemFormData({
    this.id,
    this.product,
    this.supply,
    this.quantity = 1,
    this.price = 0,
    this.priceSupply = 0,
    this.account,
    this.accountSlot,
    this.note,
    this.expiredAt,
  }) : priceSupplyController = TextEditingController(
         text: priceSupply.toString(),
       ),
       priceController = TextEditingController(text: price.toString());

  /// Create from existing OrderItem (for update mode)
  factory OrderItemFormData.fromOrderItem(OrderItem? item) {
    if (item == null) {
      return OrderItemFormData();
    }
    return OrderItemFormData(
      id: item.id,
      product: item.product,
      supply: item.supply,
      quantity: item.quantity,
      price: item.price,
      priceSupply: item.priceSupply,
      account: item.account,
      accountSlot: item.accountSlot,
      note: item.note,
      expiredAt: item.expiredAt,
    );
  }

  void dispose() {
    priceSupplyController.dispose();
    priceController.dispose();
  }

  /// Convert to OrderItem for API submission
  OrderItem toOrderItem(int? orderId) {
    return OrderItem(
      id: id,
      orderId: orderId ?? 0,
      productId: product!.id,
      supplyId: supply!.id,
      quantity: quantity,
      price: price,
      priceSupply: priceSupply,
      account: account,
      accountSlotId: accountSlot?.id,
      note: note?.isEmpty == true ? null : note,
      refundedAmount: 0,
      expiredAt: expiredAt,
    );
  }

  /// Create a copy with updated fields
  OrderItemFormData copyWith({
    int? id,
    Product? product,
    Supply? supply,
    int? quantity,
    int? price,
    int? priceSupply,
    Map<String, dynamic>? account,
    AccountSlot? accountSlot,
    String? note,
    DateTime? expiredAt,
  }) {
    return OrderItemFormData(
      id: id ?? this.id,
      product: product ?? this.product,
      supply: supply ?? this.supply,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      priceSupply: priceSupply ?? this.priceSupply,
      account: account ?? this.account,
      accountSlot: accountSlot ?? this.accountSlot,
      note: note ?? this.note,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }
}
