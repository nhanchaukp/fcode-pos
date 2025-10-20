import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/product_supply_service.dart';
import 'package:fcode_pos/ui/components/account_form_input.dart';
import 'package:fcode_pos/ui/components/account_slot_dropdown.dart';
import 'package:fcode_pos/ui/components/customer_search_dropdown.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/ui/components/order_status_dropdown.dart';
import 'package:fcode_pos/ui/components/product_search_dropdown.dart';
import 'package:fcode_pos/ui/components/quantity_input.dart';
import 'package:fcode_pos/ui/components/supply_dropdown.dart';
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
  final _orderService = AuthService();
  final _noteController = TextEditingController();

  // Order info
  User? _selectedUser;
  enums.OrderStatus _selectedStatus = enums.OrderStatus.new_;
  String? _selectedUtmSource;
  bool _isLoading = false;

  // Order items
  final List<OrderItemForm> _orderItems = [];

  final List<String> _utmSources = ['zalo', 'telegram', 'facebook'];

  @override
  void dispose() {
    _noteController.dispose();
    for (var item in _orderItems) {
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

  void _addOrderItem() {
    setState(() {
      _orderItems.add(OrderItemForm());
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems[index].dispose();
      _orderItems.removeAt(index);
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate order items
    if (_orderItems.isEmpty) {
      SnackBarHelper.error('Vui lòng thêm ít nhất một sản phẩm');
      return;
    }

    // Validate each order item
    for (int i = 0; i < _orderItems.length; i++) {
      final item = _orderItems[i];
      if (item.product == null) {
        SnackBarHelper.error('Vui lòng chọn sản phẩm cho item ${i + 1}');
        return;
      }
      if (item.supply == null) {
        SnackBarHelper.error('Vui lòng chọn nhà cung cấp cho item ${i + 1}');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final total = _calculateTotal();

      // Create order items (with orderId = 0 as placeholder, backend will handle it)
      final orderItems = _orderItems
          .map((item) => item.toOrderItem(0))
          .toList();

      // Create order with items
      final newOrder = Order(
        id: 0, // Will be assigned by backend
        userId: _selectedUser?.id ?? 0,
        total: total,
        status: _selectedStatus.value,
        type: 'new',
        note: _noteController.text.isEmpty ? null : _noteController.text,
        utmSource: _selectedUtmSource,
        items: orderItems,
        paymentHistories: [],
        refunds: [],
      );

      // Create order (with items included)
      await _orderService.create(newOrder);

      if (!mounted) return;

      SnackBarHelper.success('Tạo đơn hàng thành công');

      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      if (!mounted) return;

      SnackBarHelper.error('Lỗi: ${e.toString()}');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderInfoSection(),
                const SizedBox(height: 24),
                _buildOrderItemsSection(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildCustomerField(),
          const SizedBox(height: 16),
          _buildStatusField(),
          const SizedBox(height: 16),
          _buildUtmSourceField(),
          const SizedBox(height: 16),
          _buildNoteField(),
          const SizedBox(height: 16),
          _buildTotalDisplay(),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Sản phẩm (${_orderItems.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addOrderItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          if (_orderItems.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có sản phẩm nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addOrderItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm sản phẩm đầu tiên'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 16),
            ...List.generate(_orderItems.length, (index) {
              return _buildOrderItemCard(index);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(int index) {
    final item = _orderItems[index];
    final itemTotal = item.price * item.quantity;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      CurrencyHelper.formatCurrency(itemTotal),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => _removeOrderItem(index),
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProductSearchDropdown(
              selectedProduct: item.product,
              onProductSelected: (product) async {
                setState(() {
                  item.product = product;
                  item.price = product.priceSale ?? product.price;
                  item.priceController.text = item.price.toString();
                });

                // Load best price
                await item.loadBestPrice(
                  context,
                  onStateChanged: () {
                    setState(() {});
                  },
                );
              },
              onProductCleared: () {
                setState(() {
                  item.product = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: SupplyDropdown(
                    selectedSupply: item.supply,
                    onSupplySelected: (supply) async {
                      setState(() {
                        item.supply = supply;
                      });

                      if (item.product != null) {
                        await item.loadBestPrice(
                          context,
                          supplyId: supply.id,
                          onStateChanged: () {
                            setState(() {});
                          },
                        );
                      }
                    },
                    onSupplyCleared: () {
                      setState(() {
                        item.supply = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: QuantityInput(
                    initialQuantity: item.quantity,
                    onQuantityChanged: (quantity) {
                      setState(() {
                        item.quantity = quantity;
                      });
                    },
                    minQuantity: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MoneyFormField(
                    controller: item.priceSupplyController,
                    labelText: 'Giá vốn',
                    hintText: 'Nhập giá vốn',
                    prefixIcon: item.isLoadingBestPrice
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    onChanged: (value) {
                      item.priceSupply = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá vốn';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MoneyFormField(
                    controller: item.priceController,
                    labelText: 'Giá bán',
                    hintText: 'Nhập giá bán',
                    onChanged: (value) {
                      setState(() {
                        item.price = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá bán';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AccountFormInput(
              initialAccount: item.account,
              onAccountChanged: (account) {
                setState(() {
                  item.account = account;
                });
              },
            ),
            const SizedBox(height: 12),
            AccountSlotDropdown(
              selectedSlot: item.accountSlot,
              onSlotSelected: (slot) {
                setState(() {
                  item.accountSlot = slot;
                });
              },
              onSlotCleared: () {
                setState(() {
                  item.accountSlot = null;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: item.note,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Nhập ghi chú cho sản phẩm',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (value) {
                item.note = value;
              },
            ),
          ],
        ),
      ),
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

  Widget _buildStatusField() {
    return OrderStatusDropdown(
      initialValue: _selectedStatus,
      onChanged: (value) {
        setState(() => _selectedStatus = value ?? enums.OrderStatus.new_);
      },
    );
  }

  Widget _buildUtmSourceField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUtmSource,
      decoration: const InputDecoration(
        labelText: 'Nguồn (UTM Source)',
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

  Widget _buildTotalDisplay() {
    final total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng tiền:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            CurrencyHelper.formatCurrency(total),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      // padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCreate,
              style: ElevatedButton.styleFrom(
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

// Helper class to manage order item form state
class OrderItemForm {
  Product? product;
  Supply? supply;
  int quantity;
  int price;
  int priceSupply;
  Map<String, dynamic>? account;
  AccountSlot? accountSlot;
  String? note;
  bool isLoadingBestPrice;

  final _productSupplyService = ProductSupplyService();

  // Controllers for price fields
  final TextEditingController priceSupplyController;
  final TextEditingController priceController;

  OrderItemForm({
    this.product,
    this.supply,
    this.quantity = 1,
    this.price = 0,
    this.priceSupply = 0,
    this.account,
    this.accountSlot,
    this.note,
    this.isLoadingBestPrice = false,
  }) : priceSupplyController = TextEditingController(
         text: priceSupply.toString(),
       ),
       priceController = TextEditingController(text: price.toString());

  void dispose() {
    priceSupplyController.dispose();
    priceController.dispose();
  }

  Future<void> loadBestPrice(
    BuildContext context, {
    int? supplyId,
    VoidCallback? onStateChanged,
  }) async {
    if (product == null) return;

    isLoadingBestPrice = true;
    onStateChanged?.call();

    try {
      final bestPrice = await _productSupplyService.bestPrice(
        product!.id,
        supplyId: supplyId,
      );

      if (bestPrice != null) {
        // Auto-select supply if not specified
        if (supply == null && bestPrice.supply != null) {
          supply = bestPrice.supply;
        }
        // Auto-fill supply price
        priceSupply = bestPrice.price;
        priceSupplyController.text = bestPrice.price.toString();

        isLoadingBestPrice = false;
        onStateChanged?.call();

        if (context.mounted) {
          final message = supplyId != null
              ? 'Đã tự động điền giá nhập: ${bestPrice.price}'
              : 'Đã tự động chọn nhà cung cấp: ${bestPrice.supply?.name ?? "N/A"} - Giá: ${bestPrice.price}';

          SnackBarHelper.success(message, duration: const Duration(seconds: 2));
        }
      } else {
        isLoadingBestPrice = false;
        onStateChanged?.call();
      }
    } catch (e) {
      debugPrint('Error loading best price: $e');
      isLoadingBestPrice = false;
      onStateChanged?.call();

      if (context.mounted) {
        SnackBarHelper.error('Không thể tải giá tốt nhất');
      }
    }
  }

  OrderItem toOrderItem(int orderId) {
    return OrderItem(
      orderId: orderId,
      productId: product!.id,
      supplyId: supply!.id,
      quantity: quantity,
      price: price,
      priceSupply: priceSupply,
      account: account,
      accountSlotId: accountSlot?.id,
      note: note?.isEmpty == true ? null : note,
      refundedAmount: 0,
    );
  }
}
