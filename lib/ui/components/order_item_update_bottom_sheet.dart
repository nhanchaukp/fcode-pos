import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/account_form_input.dart';
import 'package:fcode_pos/ui/components/account_slot_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/ui/components/product_search_dropdown.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:fcode_pos/ui/components/supply_dropdown.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class OrderItemUpdateBottomSheet extends StatefulWidget {
  final OrderItem? item;
  final String? orderId;
  final VoidCallback? onSuccess;

  const OrderItemUpdateBottomSheet({
    this.item,
    this.orderId,
    this.onSuccess,
    super.key,
  }) : assert(
         item != null || orderId != null,
         'Either item or orderId must be provided',
       );

  @override
  State<OrderItemUpdateBottomSheet> createState() =>
      _OrderItemUpdateBottomSheetState();
}

class _OrderItemUpdateBottomSheetState
    extends State<OrderItemUpdateBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _productSupplyService = ProductSupplyService();
  final _priceController = TextEditingController();
  final _priceSupplyController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingBestPrice = false;
  Product? _selectedProduct;
  Supply? _selectedSupply;
  Map<String, dynamic>? _accountData;
  int _quantity = 1;
  AccountSlot? _selectedAccountSlot;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.item != null) {
      // Update mode - initialize with existing item data
      _quantity = widget.item!.quantity;
      _priceController.text = widget.item!.price.toString();
      _priceSupplyController.text = widget.item!.priceSupply.toString();
      _noteController.text = widget.item!.note ?? '';
      _selectedProduct = widget.item!.product;
      _selectedSupply = widget.item!.supply;
      _accountData = widget.item!.account;
      _selectedAccountSlot = widget.item!.accountSlot;
    } else {
      // Create mode - set defaults
      _quantity = 1;
      _priceController.text = '0';
      _priceSupplyController.text = '0';
      _noteController.text = '';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceSupplyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBestPrice(int productId, {int? supplyId}) async {
    setState(() => _isLoadingBestPrice = true);

    try {
      final result = await _productSupplyService.bestPrice(
        productId,
        supplyId: supplyId,
      );

      if (!mounted) return;

      if (result.data != null) {
        final bestPrice = result.data!;
        setState(() {
          // Nếu chưa chọn supply và API trả về supply -> tự động set
          if (_selectedSupply == null && bestPrice.supply != null) {
            _selectedSupply = bestPrice.supply;
          }
          // Tự động set giá nhập
          _priceSupplyController.text = bestPrice.price.toString();
        });

        // Show thông báo
        final message = supplyId != null
            ? 'Đã tự động điền giá nhập: ${bestPrice.price}'
            : 'Đã tự động chọn nhà cung cấp: ${bestPrice.supply?.name ?? "N/A"} - Giá: ${bestPrice.price}';

        Toastr.success(message);
      } else {
        debugPrint(
          'No best price found for product $productId ${supplyId != null ? "and supply $supplyId" : ""}',
        );
      }
    } catch (e) {
      debugPrint('Error loading best price: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBestPrice = false);
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields for create mode
    if (widget.item == null) {
      if (_selectedProduct == null) {
        Toastr.error('Vui lòng chọn sản phẩm');
        return;
      }
      if (_selectedSupply == null) {
        Toastr.error('Vui lòng chọn nhà cung cấp');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final isCreateMode = widget.item == null;
      final orderId = isCreateMode
          ? widget.orderId!
          : widget.item!.orderId.toString();

      final updatedItem = OrderItem(
        id: widget.item?.id, // 0 for new items
        orderId: int.parse(orderId),
        productId: _selectedProduct?.id ?? widget.item!.productId,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        quantity: _quantity,
        account: _accountData,
        price: _priceController.moneyValue,
        priceSupply: _priceSupplyController.moneyValue,
        supplyId: _selectedSupply?.id ?? widget.item!.supplyId,
        accountSlotId: _selectedAccountSlot?.id,
        expiredAt: widget.item?.expiredAt,
        refundedAmount: widget.item?.refundedAmount ?? 0,
      );

      // Use upsertItems to update or create the order item
      await _orderService.upsertItems(orderId, [updatedItem]);

      if (!mounted) return;

      Toastr.success(
        isCreateMode
            ? 'Đã thêm sản phẩm vào đơn hàng'
            : 'Cập nhật sản phẩm thành công',
      );

      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      Toastr.error('Đã có lỗi xảy ra. Vui lòng thử lại.');
      debugPrint('Error updating order item: $e');
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
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Thêm sản phẩm' : 'Cập nhật sản phẩm',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                ProductSearchDropdown(
                  selectedProduct: _selectedProduct,
                  onProductSelected: (product) async {
                    setState(() {
                      _selectedProduct = product;
                      // Auto update price when product changes
                      _priceController.text =
                          (product.priceSale ?? product.price).toString();
                    });

                    // Load best price and auto-select supply
                    await _loadBestPrice(product.id);
                  },
                  onProductCleared: () {
                    setState(() {
                      _selectedProduct = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 6, // give supply more space
                      child: SupplyDropdown(
                        selectedSupply: _selectedSupply,
                        onSupplySelected: (supply) async {
                          setState(() {
                            _selectedSupply = supply;
                          });

                          // Nếu đã chọn product -> tự động load giá cho supply này
                          if (_selectedProduct != null) {
                            await _loadBestPrice(
                              _selectedProduct!.id,
                              supplyId: supply.id,
                            );
                          }
                        },
                        onSupplyCleared: () {
                          setState(() {
                            _selectedSupply = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3, // make quantity field smaller
                      child: QuantityInput(
                        initialQuantity: _quantity,
                        onQuantityChanged: (quantity) {
                          setState(() {
                            _quantity = quantity;
                          });
                        },
                        minQuantity: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildPriceSupplyField()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPriceField()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAccountField(),
                const SizedBox(height: 16),
                _buildAccountSlotField(),
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

  Widget _buildPriceField() {
    return MoneyFormField(
      controller: _priceController,
      labelText: 'Giá bán',
      hintText: 'Nhập giá bán',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập giá bán';
        }
        return null;
      },
    );
  }

  Widget _buildPriceSupplyField() {
    return MoneyFormField(
      controller: _priceSupplyController,
      labelText: 'Giá vốn',
      hintText: 'Nhập giá vốn',
      prefixIcon: _isLoadingBestPrice
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập giá vốn';
        }
        return null;
      },
    );
  }

  Widget _buildAccountField() {
    return AccountFormInput(
      initialAccount: _accountData,
      onAccountChanged: (account) {
        setState(() {
          _accountData = account;
        });
      },
    );
  }

  Widget _buildAccountSlotField() {
    return AccountSlotDropdown(
      selectedSlot: _selectedAccountSlot,
      onSlotSelected: (slot) {
        setState(() {
          _selectedAccountSlot = slot;
        });
      },
      onSlotCleared: () {
        setState(() {
          _selectedAccountSlot = null;
        });
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Ghi chú',
        hintText: 'Nhập ghi chú cho sản phẩm',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
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
              : Text(widget.item == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }
}
