import 'package:fcode_pos/models.dart';
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasSku)
                    Flexible(
                      fit: FlexFit.loose,
                      child: _MetaChip(
                        icon: Icons.qr_code_2_outlined,
                        label: sku,
                      ),
                    ),
                  if (hasSku) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bestPriceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: hasSku ? TextAlign.right : TextAlign.left,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasGroup) ...[
                const SizedBox(height: 8),
                _MetaChip(icon: Icons.category_outlined, label: group),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FactChip(
                    icon: product.instock > 0
                        ? Icons.inventory_2_outlined
                        : Icons.inventory_2,
                    label: 'Tồn ${product.instock}',
                    color: product.instock > 0
                        ? colorScheme.tertiary
                        : colorScheme.error,
                  ),
                  if (product.allowBuyMulti)
                    _FactChip(
                      icon: Icons.layers_outlined,
                      label: 'Mua nhiều',
                      color: colorScheme.primary,
                    ),
                  if (product.requireAccount)
                    _FactChip(
                      icon: Icons.person_outline,
                      label: 'Cần tài khoản',
                      color: colorScheme.secondary,
                    ),
                  if (product.requirePassword)
                    _FactChip(
                      icon: Icons.password_outlined,
                      label: 'Cần mật khẩu',
                      color: colorScheme.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductListItemSkeleton extends StatelessWidget {
  const ProductListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SkeletonLine(height: 14, widthFactor: 0.6),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _SkeletonLine(height: 12, widthFactor: 0.45)),
                SizedBox(width: 8),
                _SkeletonBox(width: 96, height: 18, radius: 4),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SkeletonBox(width: 76, height: 22, radius: 999),
                _SkeletonBox(width: 92, height: 22, radius: 999),
                _SkeletonBox(width: 108, height: 22, radius: 999),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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

  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
