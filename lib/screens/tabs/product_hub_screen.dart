import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/products/customer_list_screen.dart';
import 'package:fcode_pos/screens/product-supply/product_cost_screen.dart';
import 'package:fcode_pos/screens/products/product_list_screen.dart';
import 'package:fcode_pos/screens/refund/refund_request_screen.dart';
import 'package:fcode_pos/screens/supply/suppliers_screen.dart';
import 'package:fcode_pos/screens/mail/mail_log_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _managementItems = [
    _ProductHubItem(
      title: 'Sản phẩm',
      description: 'Quản lý danh mục sản phẩm, tồn kho và giá bán.',
      icon: Icons.inventory_2_outlined,
      builder: (context) => const ProductListScreen(),
    ),
    _ProductHubItem(
      title: 'Kho tài khoản',
      description: 'Quản lý tài khoản master và slots dịch vụ.',
      icon: Icons.vpn_key_outlined,
      builder: (context) => const AccountSlotManagementScreen(),
    ),
    _ProductHubItem(
      title: 'Nhà cung cấp',
      description: 'Theo dõi và quản lý thông tin đối tác cung cấp.',
      icon: Icons.local_shipping_outlined,
      builder: (context) => const SuppliersScreen(),
    ),
    _ProductHubItem(
      title: 'Yêu cầu hoàn tiền',
      description: 'Tổ chức sản phẩm theo nhóm để báo cáo chính xác.',
      icon: Icons.replay_outlined,
      builder: (context) => const RefundRequestScreen(),
    ),
    _ProductHubItem(
      title: 'Giá nhập sản phẩm',
      description: 'Theo dõi lịch sử giá nhập và đề xuất giá bán.',
      icon: Icons.price_change_outlined,
      builder: (context) => const ProductCostScreen(),
    ),
    _ProductHubItem(
      title: 'Khách hàng',
      description: 'Quản lý hồ sơ khách hàng và lịch sử mua hàng.',
      icon: Icons.people_alt_outlined,
      builder: (context) => const CustomerListScreen(),
    ),
    _ProductHubItem(
      title: 'Nhật ký email',
      description: 'Xem và quản lý lịch sử gửi email.',
      icon: Icons.email_outlined,
      builder: (context) => const MailLogScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: _managementItems.length,
          itemBuilder: (context, index) {
            final item = _managementItems[index];
            return Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.outlineVariant.applyOpacity(0.5),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: item.builder),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 24,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductHubItem {
  const _ProductHubItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}
