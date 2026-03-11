import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/customer/customer_list_screen.dart';
import 'package:fcode_pos/screens/product-supply/product_cost_screen.dart';
import 'package:fcode_pos/screens/products/product_list_screen.dart';
import 'package:fcode_pos/screens/refund/refund_request_screen.dart';
import 'package:fcode_pos/screens/supply/suppliers_screen.dart';
import 'package:fcode_pos/screens/mail/mail_log_screen.dart';
import 'package:fcode_pos/screens/financial/financial_transaction_screen.dart';
import 'package:fcode_pos/screens/rating/rating_list_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _managementItems = [
    _ProductHubItem(
      title: 'Sản phẩm',
      description: 'Quản lý danh mục sản phẩm, tồn kho và giá bán.',
      icon: Icons.inventory_2_outlined,
      color: Colors.blue,
      builder: (context) => const ProductListScreen(),
    ),
    _ProductHubItem(
      title: 'Kho tài khoản',
      description: 'Quản lý tài khoản master và slots dịch vụ.',
      icon: Icons.vpn_key_outlined,
      color: Colors.purple,
      builder: (context) => const AccountSlotManagementScreen(),
    ),
    _ProductHubItem(
      title: 'Nhà cung cấp',
      description: 'Theo dõi và quản lý thông tin đối tác cung cấp.',
      icon: Icons.local_shipping_outlined,
      color: Colors.orange,
      builder: (context) => const SuppliersScreen(),
    ),
    _ProductHubItem(
      title: 'Yêu cầu hoàn tiền',
      description: 'Tổ chức sản phẩm theo nhóm để báo cáo chính xác.',
      icon: Icons.replay_outlined,
      color: Colors.red,
      builder: (context) => const RefundRequestScreen(),
    ),
    _ProductHubItem(
      title: 'Giá nhập sản phẩm',
      description: 'Theo dõi lịch sử giá nhập và đề xuất giá bán.',
      icon: Icons.price_change_outlined,
      color: Colors.teal,
      builder: (context) => const ProductCostScreen(),
    ),
    _ProductHubItem(
      title: 'Khách hàng',
      description: 'Quản lý hồ sơ khách hàng và lịch sử mua hàng.',
      icon: Icons.people_alt_outlined,
      color: Colors.indigo,
      builder: (context) => const CustomerListScreen(),
    ),
    _ProductHubItem(
      title: 'Nhật ký email',
      description: 'Xem và quản lý lịch sử gửi email.',
      icon: Icons.email_outlined,
      color: Colors.pink,
      builder: (context) => const MailLogScreen(),
    ),
    _ProductHubItem(
      title: 'Giao dịch tài chính',
      description: 'Xem chi tiết các giao dịch thu chi và hoàn tiền.',
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.green,
      builder: (context) => const FinancialTransactionScreen(),
    ),
    _ProductHubItem(
      title: 'Đánh giá',
      description: 'Quản lý đánh giá và nhận xét từ khách hàng.',
      icon: Icons.star_outline,
      color: Colors.amber,
      builder: (context) => const RatingListScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: _managementItems.length,
          itemBuilder: (context, index) {
            final item = _managementItems[index];
            final itemColor = item.color ?? colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: item.builder),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: itemColor.applyOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, size: 24, color: itemColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colorScheme.onSurfaceVariant.applyOpacity(0.5),
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
    this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
  final Color? color;
}
