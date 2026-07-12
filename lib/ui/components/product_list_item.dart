import 'package:amazing_icons/twotone.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/ui/components/badge_twotone_icon.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bestPrice = product.bestPrice ?? product.price;
    final hasBestPrice = bestPrice > 0;
    final bestPriceLabel = hasBestPrice
        ? CurrencyHelper.formatCurrency(bestPrice)
        : 'Liên hệ';

    final sku = product.sku?.trim();
    final group = product.group?.trim();
    final hasSku = sku != null && sku.isNotEmpty;
    final hasGroup = group != null && group.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bestPriceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (hasSku || hasGroup) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (hasSku)
                    _MetaChip(icon: AmazingIconTwotone.scanBarcode, label: sku),
                  if (hasGroup)
                    _MetaChip(icon: AmazingIconTwotone.category, label: group),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _FactChip(
                  icon: product.instock > 0
                      ? AmazingIconTwotone.box
                      : AmazingIconTwotone.boxRemove,
                  label: 'Tồn ${product.instock}',
                  color: product.instock > 0
                      ? colorScheme.tertiary
                      : colorScheme.error,
                ),
                if (product.allowBuyMulti)
                  _FactChip(
                    icon: AmazingIconTwotone.layer,
                    label: 'Mua nhiều',
                    color: colorScheme.primary,
                  ),
                if (product.requireAccount)
                  _FactChip(
                    icon: AmazingIconTwotone.profile,
                    label: 'Cần tài khoản',
                    color: colorScheme.secondary,
                  ),
                if (product.requirePassword)
                  _FactChip(
                    icon: AmazingIconTwotone.lock,
                    label: 'Cần mật khẩu',
                    color: colorScheme.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductListItemSkeleton extends StatelessWidget {
  const ProductListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(child: _SkeletonLine(height: 14, widthFactor: 0.6)),
              SizedBox(width: 8),
              _SkeletonBox(width: 80, height: 16, radius: 4),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _SkeletonBox(width: 70, height: 18, radius: 5),
              _SkeletonBox(width: 90, height: 18, radius: 5),
            ],
          ),
          SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _SkeletonBox(width: 66, height: 20, radius: 999),
              _SkeletonBox(width: 82, height: 20, radius: 999),
              _SkeletonBox(width: 98, height: 20, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final TwotoneIconBuilder icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon(size: 12, color: color, opacity: 0.45),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final TwotoneIconBuilder icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon(size: 12, color: color, opacity: 0.45),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.height, required this.widthFactor});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: _SkeletonBox(height: height),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
