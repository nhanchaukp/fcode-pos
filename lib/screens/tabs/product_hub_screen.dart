import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/account-vault/account_vault_list_screen.dart';
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
import 'package:fcode_pos/screens/coupon/coupon_list_screen.dart';
import 'package:fcode_pos/screens/telegram-bot/telegram_bot_hub_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _sections = [
    _Section(
      title: 'Khám phá',
      items: [
        _Item(
          'Sản phẩm',
          Icons.inventory_2_rounded,
          Colors.blue,
          (c) => const ProductListScreen(),
        ),
        _Item(
          'Kho tài khoản',
          Icons.vpn_key_rounded,
          Colors.purple,
          (c) => const AccountSlotManagementScreen(),
        ),
        _Item(
          'Account Vault',
          Icons.lock_person_rounded,
          Colors.deepPurple,
          (c) => const AccountVaultListScreen(),
        ),
        _Item(
          'Nhà cung cấp',
          Icons.local_shipping_rounded,
          Colors.orange,
          (c) => const SuppliersScreen(),
        ),
        _Item(
          'Hoàn tiền',
          Icons.replay_rounded,
          Colors.red,
          (c) => const RefundRequestScreen(),
        ),
        _Item(
          'Giá nhập',
          Icons.price_change_rounded,
          Colors.teal,
          (c) => const ProductCostScreen(),
        ),
        _Item(
          'Khách hàng',
          Icons.people_alt_rounded,
          Colors.indigo,
          (c) => const CustomerListScreen(),
        ),
        _Item(
          'Nhật ký email',
          Icons.email_rounded,
          Colors.pink,
          (c) => const MailLogScreen(),
        ),
        _Item(
          'Tài chính',
          Icons.account_balance_wallet_rounded,
          Colors.green,
          (c) => const FinancialTransactionScreen(),
        ),
        _Item(
          'Đánh giá',
          Icons.star_rounded,
          Colors.amber,
          (c) => const RatingListScreen(),
        ),
        _Item(
          'Mã giảm giá',
          Icons.confirmation_number_rounded,
          Colors.deepPurple,
          (c) => const CouponListScreen(),
        ),
        _Item(
          'Hóa đơn ĐT',
          Icons.receipt_long_rounded,
          Colors.cyan,
          (c) => const InvoiceListScreen(),
        ),
      ],
    ),
    _Section(
      title: 'Tính năng khác',
      items: [
        _Item(
          'Google Adsense',
          Icons.bar_chart_rounded,
          Colors.deepOrange,
          (c) => const AdsenseScreen(),
        ),
        _Item(
          'ChatGPT',
          Icons.smart_toy_rounded,
          Colors.blueGrey,
          (c) => const ChatGptSessionScreen(),
        ),
        _Item(
          'Icallme',
          Icons.confirmation_number_rounded,
          Colors.deepPurple,
          (c) => const IcallmeVoucherScreen(),
        ),
        _Item(
          'Telegram Bot',
          Icons.smart_toy_rounded,
          Colors.lightBlue,
          (c) => const TelegramBotHubScreen(),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          itemCount: _sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 20),
          itemBuilder: (context, i) => _SectionView(section: _sections[i]),
        ),
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            section.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
        ),
        _ItemGrid(items: section.items),
      ],
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.72,
      children: items.map((item) => _GridCell(item: item)).toList(),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: item.builder)),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: item.color.applyOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 26, color: item.color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Section {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_Item> items;
}

class _Item {
  const _Item(this.title, this.icon, this.color, this.builder);
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}
