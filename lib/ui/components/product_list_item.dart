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
    final bestPriceLabel =
        bestPrice > 0 ? CurrencyHelper.formatCurrency(bestPrice) : '—';
    final instockLabel = product.instock.toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (product.sku != null) ...[
                _IconValue(
                  icon: Icons.qr_code_2_outlined,
                  value: product.sku!,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Tooltip(
                    message:
                        product.isActive ? 'Đang hoạt động' : 'Đã tạm dừng',
                    child: Icon(
                      product.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: product.isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _IconValue(
                    icon: Icons.price_change_outlined,
                    value: bestPriceLabel,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _IconValue(
                    icon: Icons.inventory_2_outlined,
                    value: instockLabel,
                    color: colorScheme.tertiary,
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

class _IconValue extends StatelessWidget {
  const _IconValue({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
