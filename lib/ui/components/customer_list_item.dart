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
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 20, child: Text(initial)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: IconText(
                      icon: Icons.account_balance_wallet_outlined,
                      value: balanceLabel,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (facebookUrl != null && facebookUrl.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
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
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                CopyableIconText(
                  icon: Icons.phone_outlined,
                  value: phone,
                  color: colorScheme.tertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
