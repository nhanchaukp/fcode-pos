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
import 'package:fcode_pos/screens/coupon/coupon_list_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  static final _sections = [
    _Section(
      title: 'Quản lý',
      items: [
        _Item('Sản phẩm', Icons.inventory_2_rounded, Colors.blue,
            (c) => const ProductListScreen()),
        _Item('Kho tài khoản', Icons.vpn_key_rounded, Colors.purple,
            (c) => const AccountSlotManagementScreen()),
        _Item('Nhà cung cấp', Icons.local_shipping_rounded, Colors.orange,
            (c) => const SuppliersScreen()),
        _Item('Hoàn tiền', Icons.replay_rounded, Colors.red,
            (c) => const RefundRequestScreen()),
        _Item('Giá nhập', Icons.price_change_rounded, Colors.teal,
            (c) => const ProductCostScreen()),
        _Item('Khách hàng', Icons.people_alt_rounded, Colors.indigo,
            (c) => const CustomerListScreen()),
        _Item('Nhật ký email', Icons.email_rounded, Colors.pink,
            (c) => const MailLogScreen()),
        _Item('Tài chính', Icons.account_balance_wallet_rounded, Colors.green,
            (c) => const FinancialTransactionScreen()),
        _Item('Đánh giá', Icons.star_rounded, Colors.amber,
            (c) => const RatingListScreen()),
        _Item('Mã giảm giá', Icons.confirmation_number_rounded, Colors.deepPurple,
            (c) => const CouponListScreen()),
        _Item('Hóa đơn ĐT', Icons.receipt_long_rounded, Colors.cyan,
            (c) => const InvoiceListScreen()),
      ],
    ),
    _Section(
      title: 'Tính năng khác',
      items: [
        _Item('Google Adsense', Icons.bar_chart_rounded, Colors.deepOrange,
            (c) => const AdsenseScreen()),
        _Item('ChatGPT', Icons.smart_toy_rounded, Colors.blueGrey,
            (c) => const ChatGptSessionScreen()),
        _Item('Icallme', Icons.confirmation_number_rounded, Colors.deepPurple,
            (c) => const IcallmeVoucherScreen()),
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
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            section.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _ItemGrid(items: section.items),
        ),
      ],
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});
  final List<_Item> items;

  static const _cols = 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = (items.length / _cols).ceil();

    return Column(
      children: List.generate(rows, (row) {
        final start = row * _cols;
        final end = (start + _cols).clamp(0, items.length);
        final rowItems = items.sublist(start, end);
        return Column(
          children: [
            if (row > 0)
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            IntrinsicHeight(
              child: Row(
                children: List.generate(_cols, (col) {
                  if (col >= rowItems.length) {
                    return const Expanded(child: SizedBox());
                  }
                  return Expanded(
                    child: _GridCell(
                      item: rowItems[col],
                      showRightBorder: col < _cols - 1 && col < rowItems.length - 1,
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.item, this.showRightBorder = false});
  final _Item item;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showRightBorder
            ? Border(
                right: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              )
            : const BoxDecoration().border ?? const Border(),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: item.builder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.applyOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
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
