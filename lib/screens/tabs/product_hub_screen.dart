import 'package:fcode_pos/screens/account-master/account_slot_management_screen.dart';
import 'package:fcode_pos/screens/account-master/account_master_stats_screen.dart';
import 'package:fcode_pos/screens/account-vault/account_vault_list_screen.dart';
import 'package:fcode_pos/screens/customer/customer_list_screen.dart';
import 'package:fcode_pos/screens/customer/customer_stats_screen.dart';
import 'package:fcode_pos/screens/financial/financial_report_screen.dart';
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
import 'package:fcode_pos/screens/tabs/report_screen.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';

/// Builder cho icon bulk của amazing_icons.
typedef BulkIconBuilder =
    Widget Function({double size, Color color, double opacity});

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _sections = [
    _Section(
      title: 'Quản lí cửa hàng',
      items: [
        _Item(
          'Sản phẩm',
          AmazingIconBulk.box,
          Colors.blue,
          (c) => const ProductListScreen(),
        ),
        _Item(
          'Kho tài khoản',
          AmazingIconBulk.key,
          Colors.purple,
          (c) => const AccountSlotManagementScreen(),
        ),
        _Item(
          'Ví tài khoản',
          AmazingIconBulk.shieldSecurity,
          Colors.deepPurple,
          (c) => const AccountVaultListScreen(),
        ),
        _Item(
          'Nhà cung cấp',
          AmazingIconBulk.truck,
          Colors.orange,
          (c) => const SuppliersScreen(),
        ),
        _Item(
          'Hoàn tiền',
          AmazingIconBulk.moneyRecive,
          Colors.red,
          (c) => const RefundRequestScreen(),
        ),
        _Item(
          'Giá nhập',
          AmazingIconBulk.tag,
          Colors.teal,
          (c) => const ProductCostScreen(),
        ),
        _Item(
          'Khách hàng',
          AmazingIconBulk.profile2user,
          Colors.indigo,
          (c) => const CustomerListScreen(),
        ),
        _Item(
          'Nhật ký email',
          AmazingIconBulk.email,
          Colors.pink,
          (c) => const MailLogScreen(),
        ),
        _Item(
          'Tài chính',
          AmazingIconBulk.wallet,
          Colors.green,
          (c) => const FinancialTransactionScreen(),
        ),
        _Item(
          'Đánh giá',
          AmazingIconBulk.medalStar,
          Colors.amber,
          (c) => const RatingListScreen(),
        ),
        _Item(
          'Mã giảm giá',
          AmazingIconBulk.ticketDiscount,
          Colors.deepPurple,
          (c) => const CouponListScreen(),
        ),
        _Item(
          'Hóa đơn ĐT',
          AmazingIconBulk.receiptText,
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
          AmazingIconBulk.statusUp,
          Colors.deepOrange,
          (c) => const AdsenseScreen(),
        ),
        _Item(
          'ChatGPT',
          AmazingIconBulk.messageProgramming,
          Colors.blueGrey,
          (c) => const ChatGptSessionScreen(),
        ),
        _Item(
          'Icallme',
          AmazingIconBulk.ticket,
          Colors.deepPurple,
          (c) => const IcallmeVoucherScreen(),
        ),
        _Item(
          'Telegram Bot',
          AmazingIconBulk.send2,
          Colors.lightBlue,
          (c) => const TelegramBotHubScreen(),
        ),
      ],
    ),
    _Section(
      title: 'Báo cáo',
      items: [
        _Item(
          'Doanh thu',
          AmazingIconBulk.chart,
          Colors.pink,
          (c) => const DashboardScreen(),
        ),
        _Item(
          'Tài chính',
          AmazingIconBulk.chartSquare,
          Colors.green,
          (c) => const FinancialReportScreen(),
        ),
        _Item(
          'Khách hàng',
          AmazingIconBulk.profile2user,
          Colors.indigo,
          (c) => const CustomerStatsScreen(),
        ),
        _Item(
          'Tài khoản chính',
          AmazingIconBulk.key,
          Colors.indigo,
          (c) => const AccountMasterStatsScreen(),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Khám phá',
      showBack: false,
      body: (context, scrollController) => ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (context, i) => _SectionView(section: _sections[i]),
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
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 0.92,
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: item.icon(size: 28, color: item.color, opacity: 0.4),
              ),
            ),
            const SizedBox(height: 4),
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
  final BulkIconBuilder icon;
  final Color color;
  final WidgetBuilder builder;
}
