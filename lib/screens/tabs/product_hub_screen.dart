import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/customer/customer_list_screen.dart';
import 'package:fcode_pos/screens/invoice/invoice_list_screen.dart';
import 'package:fcode_pos/screens/product-supply/product_cost_screen.dart';
import 'package:fcode_pos/screens/products/product_list_screen.dart';
import 'package:fcode_pos/screens/refund/refund_request_screen.dart';
import 'package:fcode_pos/screens/supply/suppliers_screen.dart';
import 'package:fcode_pos/screens/mail/mail_log_screen.dart';
import 'package:fcode_pos/screens/financial/financial_transaction_screen.dart';
import 'package:fcode_pos/screens/adsense/adsense_screen.dart';
import 'package:fcode_pos/screens/chatgpt/chatgpt_session_screen.dart';
import 'package:fcode_pos/screens/icallme/icallme_voucher_screen.dart';
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
        _ProductHubItem(
          title: 'Hóa đơn điện tử',
          icon: Icons.receipt_long_outlined,
          color: Colors.teal,
          builder: (context) => const InvoiceListScreen(),
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
        _ProductHubItem(
          title: 'Icallme Voucher',
          icon: Icons.confirmation_number_outlined,
          color: Colors.deepPurple,
          builder: (context) => const IcallmeVoucherScreen(),
        ),
      ],
    ),
  ];

  static const _crossAxisCount = 3;
  static const _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _buildSection(context, _sections[i]),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _ProductHubSection section) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = section.items;
    final remainder = items.length % _crossAxisCount;
    final placeholders =
        remainder == 0 ? 0 : _crossAxisCount - remainder;
    final total = items.length + placeholders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(_spacing),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                childAspectRatio: 1,
                crossAxisSpacing: _spacing,
                mainAxisSpacing: _spacing,
              ),
              itemCount: total,
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const _PlaceholderGridItem();
                }
                final item = items[index];
                final itemColor = item.color ?? colorScheme.primary;
                return _GridItem(
                  item: item,
                  itemColor: itemColor,
                  colorScheme: colorScheme,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.item,
    required this.itemColor,
    required this.colorScheme,
  });

  final _ProductHubItem item;
  final Color itemColor;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: item.builder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: itemColor.applyOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, size: 22, color: itemColor),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderGridItem extends StatelessWidget {
  const _PlaceholderGridItem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.applyOpacity(0.35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
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
