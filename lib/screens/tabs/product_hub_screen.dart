import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/products/customer_list_screen.dart';
import 'package:fcode_pos/screens/product-supply/product_cost_screen.dart';
import 'package:fcode_pos/screens/products/product_list_screen.dart';
import 'package:fcode_pos/screens/refund/refund_request_screen.dart';
import 'package:fcode_pos/screens/supply/suppliers_screen.dart';
import 'package:fcode_pos/screens/mail/mail_log_screen.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemBuilder: (context, index) {
            final item = _managementItems[index];
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                  child: Icon(item.icon),
                ),
                title: Text(item.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: item.builder),
                  );
                },
              ),
            );
          },
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemCount: _managementItems.length,
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
