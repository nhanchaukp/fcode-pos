import 'package:fcode_pos/ui/components/copyable_icon_text.dart';
import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/utils/image_clipboard.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:fcode_pos/utils/string_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/order_status_split_button.dart';
import 'package:fcode_pos/ui/components/order_update_bottom_sheet.dart';
import 'package:fcode_pos/ui/components/order_item_update_bottom_sheet.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:fcode_pos/utils/extensions/colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late OrderService _orderService;
  Order? _order;
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Quick access to theme
  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  Future<void> _loadOrderDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _orderService.detail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = response.data;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrintStack(
        stackTrace: st,
        label: 'Error loading order detail: ${e.toString()}',
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showUpdateDialog() async {
    if (_order == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => OrderUpdateBottomSheet(
        order: _order!,
        onSuccess: () {
          // Reload order detail after successful update
          _loadOrderDetail();
        },
      ),
    );

    // Optional: Show a message or perform additional actions if needed
    if (result == true && mounted) {
      // Dialog was closed after successful update
      debugPrint('Order updated successfully');
    }
  }

  Future<void> _showQrCodeDialog() async {
    if (_order == null ||
        _order!.urlQrCodePayment == null ||
        _order!.urlQrCodePayment!.isEmpty) {
      Toastr.error('Không có mã QR thanh toán');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã QR Thanh Toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Image.network(
                _order!.urlQrCodePayment!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không thể tải ảnh QR',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _copyQrCodeToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Sao chép'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _downloadQrCode(),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickStatusChange(enums.OrderStatus status) async {
    if (_order == null || _isUpdatingStatus) return;
    if (_order!.status == status.value) return;

    setState(() => _isUpdatingStatus = true);

    final currentOrder = _order!;

    final updatedOrder = Order(
      id: currentOrder.id,
      userId: currentOrder.userId,
      total: currentOrder.total,
      status: status.value,
      type: currentOrder.type,
      note: currentOrder.note,
      utmSource: currentOrder.utmSource,
      items: const [],
      paymentHistories: const [],
      refunds: const [],
    );

    try {
      await _orderService.update(currentOrder.id.toString(), updatedOrder);

      if (!mounted) return;

      setState(() {
        _order = Order(
          id: currentOrder.id,
          userId: currentOrder.userId,
          total: currentOrder.total,
          discount: currentOrder.discount,
          status: status.value,
          type: currentOrder.type,
          refundAmount: currentOrder.refundAmount,
          note: currentOrder.note,
          transactionId: currentOrder.transactionId,
          createdAt: currentOrder.createdAt,
          updatedAt: DateTime.now(),
          paymentId: currentOrder.paymentId,
          utmSource: currentOrder.utmSource,
          user: currentOrder.user,
          items: currentOrder.items,
          itemCount: currentOrder.itemCount,
          paymentHistories: currentOrder.paymentHistories,
          refunds: currentOrder.refunds,
          urlQrCodePayment: currentOrder.urlQrCodePayment,
        );
      });

      Toastr.success('Đã cập nhật trạng thái đơn hàng');
    } catch (e, st) {
      debugPrintStack(
        stackTrace: st,
        label: 'Error updating order status: ${e.toString()}',
      );

      if (!mounted) return;
      Toastr.error('Cập nhật trạng thái thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _copyQrCodeToClipboard() async {
    if (_order?.urlQrCodePayment == null) return;

    try {
      await ImageClipboard.copyFromUrl(_order!.urlQrCodePayment!);
      Toastr.success('Mã QR đã được sao chép vào clipboard');
    } catch (e) {
      debugPrint('Error copying QR code to clipboard: $e');
      Toastr.error('Lỗi khi sao chép mã QR: ${e.toString()}');
    }
  }

  Future<void> _downloadQrCode() async {
    if (_order?.urlQrCodePayment == null) return;

    try {
      // Download image

      final response = await http.get(Uri.parse(_order!.urlQrCodePayment!));

      if (response.statusCode == 200) {
        // Save to gallery
        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 100,
          name:
              'qr_code_order_${_order!.id}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          if (result['isSuccess'] == true) {
            Toastr.success('Đã lưu ảnh vào thư viện');
          } else {
            Toastr.error('Không thể lưu ảnh');
          }
        }
      } else {
        if (mounted) {
          Toastr.error('Không thể tải xuống ảnh');
        }
      }
    } catch (e) {
      debugPrint('Error downloading QR code: $e');
      if (mounted) {
        Toastr.error('Lỗi khi tải xuống: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Đơn hàng #${widget.orderId}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _order != null ? () => _showQrCodeDialog() : null,
            tooltip: 'Hiện thị mã QR',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _order != null ? () => _showUpdateDialog() : null,
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Không tìm thấy đơn hàng'));
    }

    final order = _order!;

    return Column(
      children: [
        // Card thông tin đơn hàng
        _buildOrderInfoCard(order),

        // Tab section
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'Sản phẩm'),
              Tab(icon: Icon(Icons.payment), text: 'Thanh toán'),
              Tab(icon: Icon(Icons.money_off), text: 'Hoàn tiền'),
            ],
          ),
        ),

        // Tab view
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductsTab(order),
              _buildPaymentHistoryTab(order),
              _buildRefundHistoryTab(order),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard(Order order) {
    final createdAt = order.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID, Status, Customer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: InkWell(
                            onTap: order.user != null
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomerDetailScreen(
                                          userId: order.user?.id,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(
                              order.user?.name ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Customer info
                    _buildCustomerInfo(order.user),
                  ],
                ),
              ),
              OrderStatusSplitButton(
                status: order.status,
                isUpdating: _isUpdatingStatus,
                onPrimaryPressed: () {
                  _showUpdateDialog();
                },
                onStatusSelected: _handleQuickStatusChange,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Financial Summary (compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side - breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactAmount(
                      'Giảm',
                      -(order.discount!),
                      color: colorScheme.secondary,
                    ),
                    _buildCompactAmount(
                      'Hoàn',
                      order.refundAmount!,
                      color: colorScheme.error,
                    ),
                  ],
                ),
              ),
              // Right side - final amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Thành tiền',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    CurrencyHelper.formatCurrency(order.total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer: Time & Source (compact)
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                DateHelper.formatDateTimeShort(createdAt),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Icon(Icons.edit_calendar, size: 12, color: colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                DateHelper.formatDateTimeShort(order.updatedAt),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Icon(Icons.link, size: 12, color: colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                order.utmSource ?? 'Direct',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
              ),
            ],
          ),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.note, size: 12, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  order.note!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(User? user) {
    if (user == null) {
      return Text(
        'N/A',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        if (user.email.isNotEmpty) ...[
          if (user.name.isNotEmpty) const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: 14,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: colorScheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
        // Phone (clickable)
        if (user.phone != null && user.phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          CopyableIconText(
            icon: Icons.phone,
            value: user.phone!,
            color: colorScheme.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactAmount(String label, int amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 4),
          Text(
            CurrencyHelper.formatCurrency(amount.abs()),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(Order order) {
    if (order.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrderDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không có sản phẩm nào'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddProductBottomSheet(order.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm sản phẩm'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      child: Column(
        children: [
          // Add product button at the top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showAddProductBottomSheet(order.id),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Products list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return _buildProductItem(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    final accountSlot = item.accountSlot;
    final hasSlot = accountSlot != null;

    return InkWell(
      onTap: () => _showItemUpdateBottomSheet(item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name & price
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.product?.name ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Nhập từ: ${item.supply?.name ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyHelper.formatCurrency(item.priceSupply),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Số lượng: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyHelper.formatCurrency(item.price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Account slot information (compact)
            if (hasSlot) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          accountSlot.accountMaster?.username ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.applyOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        // Copy button for Netflix
                        if (accountSlot.accountMaster?.serviceType
                                .toLowerCase() ==
                            'netflix')
                          InkWell(
                            onTap: () => _copyAccountInfo(accountSlot),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: colorScheme.onSurface.applyOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactSlotInfo(
                            const Icon(Icons.account_circle),
                            accountSlot.name,
                          ),
                        ),
                        Expanded(
                          child: _buildCompactSlotInfo(
                            const Icon(Icons.lock),
                            accountSlot.pin,
                          ),
                        ),
                        if (accountSlot.expiryDate != null)
                          _buildCompactSlotInfo(
                            const Icon(Icons.calendar_today),
                            DateHelper.formatDate(accountSlot.expiryDate),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // Account display if exist, display key|value format
            if (item.account != null && item.account!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          StringHelper.formatAccountString(item.account!),
                          style: TextStyle(fontSize: 11),
                        ),
                        InkWell(
                          onTap: () => _copyRawAccountInfo(item.account!),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showItemUpdateBottomSheet(OrderItem item) async {
    if (_order == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => OrderItemUpdateBottomSheet(
        orderId: _order!.id,
        orderItem: item,
        onSuccess: () {
          // Reload order detail after successful update
          _loadOrderDetail();
        },
      ),
    );

    if (result == true && mounted) {
      debugPrint('Order item updated successfully');
    }
  }

  Future<void> _showAddProductBottomSheet(int orderId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => OrderItemUpdateBottomSheet(
        orderId: orderId,
        orderItem: null,
        onSuccess: () {
          // Reload order detail after successful addition
          _loadOrderDetail();
        },
      ),
    );

    if (result == true && mounted) {
      debugPrint('Product added successfully');
    }
  }

  Widget _buildCompactSlotInfo(Icon icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            icon.icon,
            size: 12,
            color: colorScheme.onSurface.applyOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.applyOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab(Order order) {
    if (order.paymentHistories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrderDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: colorScheme.onSurface),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử thanh toán',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: order.paymentHistories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final payment = order.paymentHistories[index];
          return _buildPaymentHistoryItem(payment);
        },
      ),
    );
  }

  Widget _buildPaymentHistoryItem(PaymentHistory payment) {
    final statusColor = _getPaymentStatusColor(payment.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyHelper.formatCurrency(payment.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.applyOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (payment.paymentMethod != null)
            _buildPaymentInfo('Phương thức', payment.paymentMethod!),
          if (payment.transactionReference != null)
            _buildPaymentInfo('Mã GD', payment.transactionReference!),
          if (payment.createdAt != null)
            _buildPaymentInfo(
              'Thời gian',
              DateHelper.formatDateTime(payment.createdAt),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundHistoryTab(Order order) {
    if (order.refunds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrderDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.money_off, size: 64, color: colorScheme.onSurface),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử hoàn tiền',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: order.refunds.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final refund = order.refunds[index];
          return _buildRefundItem(refund);
        },
      ),
    );
  }

  Widget _buildRefundItem(dynamic refund) {
    // Parse refund data based on its structure
    final amount = int.tryParse(refund['amount']?.toString() ?? '0') ?? 0;
    final reason = refund['reason']?.toString() ?? 'N/A';
    final createdAt = refund['created_at'] != null
        ? DateTime.parse(refund['created_at'].toString())
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyHelper.formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Icon(Icons.money_off, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          _buildPaymentInfo('Lý do', reason),
          if (createdAt != null)
            _buildPaymentInfo(
              'Thời gian',
              DateHelper.formatDateTime(createdAt),
            ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return colorScheme.onSurface;
    }
  }

  Future<void> _copyRawAccountInfo(Map<String, dynamic> account) async {
    final copyText = StringHelper.formatAccountString(account);

    await Clipboard.setData(ClipboardData(text: copyText));

    if (mounted) {
      Toastr.success('Đã copy thông tin tài khoản');
    }
  }

  Future<void> _copyAccountInfo(AccountSlot accountSlot) async {
    final username = accountSlot.accountMaster?.username ?? 'N/A';
    final slot = accountSlot.name;
    final pin = accountSlot.pin;
    final password = accountSlot.accountMaster?.password ?? 'N/A';

    final copyText =
        '''- Tài khoản: $username
- Mật khẩu: $password
- Slot: $slot
- Pin: $pin''';

    await Clipboard.setData(ClipboardData(text: copyText));

    if (mounted) {
      Toastr.success('Đã copy thông tin tài khoản');
    }
  }
}
