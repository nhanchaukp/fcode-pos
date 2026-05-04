import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/customer/customer_list_screen.dart';
import 'package:fcode_pos/screens/product-supply/product_cost_screen.dart';
import 'package:fcode_pos/screens/products/product_list_screen.dart';
import 'package:fcode_pos/screens/refund/refund_request_screen.dart';
import 'package:fcode_pos/screens/supply/suppliers_screen.dart';
import 'package:fcode_pos/screens/mail/mail_log_screen.dart';
import 'package:fcode_pos/screens/financial/financial_transaction_screen.dart';
import 'package:fcode_pos/screens/adsense/adsense_screen.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_session_screen.dart';
import 'package:fcode_pos/screens/rating/rating_list_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _sections = [
    _ProductHubSection(
      title: 'Quản lý',
      items: [
        _ProductHubItem(
          title: 'Sản phẩm',
          icon: Icons.inventory_2_outlined,
          color: Colors.blue,
          builder: (context) => const ProductListScreen(),
        ),
        _ProductHubItem(
          title: 'Kho tài khoản',
          icon: Icons.vpn_key_outlined,
          color: Colors.purple,
          builder: (context) => const AccountSlotManagementScreen(),
        ),
        _ProductHubItem(
          title: 'Nhà cung cấp',
          icon: Icons.local_shipping_outlined,
          color: Colors.orange,
          builder: (context) => const SuppliersScreen(),
        ),
        _ProductHubItem(
          title: 'Yêu cầu hoàn tiền',
          icon: Icons.replay_outlined,
          color: Colors.red,
          builder: (context) => const RefundRequestScreen(),
        ),
        _ProductHubItem(
          title: 'Giá nhập sản phẩm',
          icon: Icons.price_change_outlined,
          color: Colors.teal,
          builder: (context) => const ProductCostScreen(),
        ),
        _ProductHubItem(
          title: 'Khách hàng',
          icon: Icons.people_alt_outlined,
          color: Colors.indigo,
          builder: (context) => const CustomerListScreen(),
        ),
        _ProductHubItem(
          title: 'Nhật ký email',
          icon: Icons.email_outlined,
          color: Colors.pink,
          builder: (context) => const MailLogScreen(),
        ),
        _ProductHubItem(
          title: 'Giao dịch tài chính',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
          builder: (context) => const FinancialTransactionScreen(),
        ),
        _ProductHubItem(
          title: 'Đánh giá',
          icon: Icons.star_outline,
          color: Colors.amber,
          builder: (context) => const RatingListScreen(),
        ),
      ],
    ),
    _ProductHubSection(
      title: 'Tính năng khác',
      items: [
        _ProductHubItem(
          title: 'Google Adsense',
          icon: Icons.bar_chart_outlined,
          color: Colors.deepOrange,
          builder: (context) => const AdsenseScreen(),
        ),
        _ProductHubItem(
          title: 'ChatGPT Sessions',
          icon: Icons.smart_toy_outlined,
          color: Colors.cyan,
          builder: (context) => const ChatGptSessionScreen(),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = colorScheme.outlineVariant.applyOpacity(0.4);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: _sections
              .map((section) => _buildSection(context, section, dividerColor))
              .expand((slivers) => slivers)
              .toList(),
        ),
      ),
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    _ProductHubSection section,
    Color dividerColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(child: _SectionHeader(title: section.title)),
      SliverToBoxAdapter(
        child: Divider(height: 1, thickness: 1, color: dividerColor),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = section.items[index];
              final itemColor = item.color ?? colorScheme.primary;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: item.builder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: itemColor.applyOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, size: 24, color: itemColor),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: section.items.length,
          ),
        ),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest.applyOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _ProductHubSection {
  const _ProductHubSection({required this.title, required this.items});

  final String title;
  final List<_ProductHubItem> items;
}

class _ProductHubItem {
  const _ProductHubItem({
    required this.title,
    required this.icon,
    required this.builder,
    this.color,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final Color? color;
}
