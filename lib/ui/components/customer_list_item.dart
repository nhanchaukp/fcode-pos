import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/ui/components/copyable_icon_text.dart';
import 'package:fcode_pos/ui/components/icon_text.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/functions.dart';
import 'package:flutter/material.dart';

class CustomerListItem extends StatelessWidget {
  const CustomerListItem({super.key, required this.user, this.onTap});

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = user.name.isNotEmpty ? user.name : user.username;
    final email = user.email;
    final facebookUrl = user.facebookUrl;
    final balanceLabel = CurrencyHelper.formatCurrency(user.balance);
    final phone = user.phone;

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
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.mail_outlined,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if ((phone != null && phone.isNotEmpty) ||
                (facebookUrl != null && facebookUrl.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (phone != null && phone.isNotEmpty)
                    Flexible(
                      child: CopyableIconText(
                        icon: Icons.phone_outlined,
                        value: phone,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  if (phone != null &&
                      phone.isNotEmpty &&
                      facebookUrl != null &&
                      facebookUrl.isNotEmpty)
                    const SizedBox(width: 12),
                  if (facebookUrl != null && facebookUrl.isNotEmpty)
                    Flexible(
                      child: InkWell(
                        onTap: () => openUrl(facebookUrl),
                        child: IconText(
                          icon: Icons.link,
                          value: 'Facebook',
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
