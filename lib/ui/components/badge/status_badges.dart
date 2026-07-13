import 'package:amazing_icons/bulk.dart';
import 'package:fcode_pos/config/app_color.dart';
import 'package:fcode_pos/ui/components/badge/app_badge.dart';
import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';

/// Badge trạng thái kích hoạt (đang dùng / vô hiệu).
class ActiveStatusBadge extends StatelessWidget {
  const ActiveStatusBadge({
    super.key,
    required this.isActive,
    this.size = BadgeSize.compact,
  });

  final bool isActive;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: isActive ? 'Đang dùng' : 'Vô hiệu',
      color: isActive ? AppColor.green : AppColor.gray,
      showIcon: false,
      size: size,
      fontWeight: FontWeight.w600,
    );
  }
}

/// Badge hiển thị thông tin credential (password, client ID, ...).
class CredBadge extends StatelessWidget {
  const CredBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.size = BadgeSize.compact,
  });

  final BulkIconBuilder icon;
  final String label;
  final Color? color;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBadge(
      label: label,
      color: color ?? cs.primary,
      bulkIcon: icon,
      size: size,
    );
  }
}

/// Badge trạng thái vị trí truy cập (success / khác).
class LocationStatusBadge extends StatelessWidget {
  const LocationStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.compact,
  });

  final String? status;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim();
    final isSuccess = normalized?.toLowerCase() == 'success';
    final label =
        (normalized == null || normalized.isEmpty) ? 'N/A' : normalized;

    return AppBadge(
      label: label,
      color: isSuccess ? AppColor.green : AppColor.orange,
      showIcon: false,
      size: size,
    );
  }
}

/// Badge hiển thị trạng thái hết hạn.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.isExpired,
    this.size = BadgeSize.compact,
  });

  final bool isExpired;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: isExpired ? 'Đã hết hạn' : 'Còn hiệu lực',
      color: isExpired ? AppColor.red : AppColor.green,
      bulkIcon: isExpired ? AmazingIconBulk.danger : AmazingIconBulk.tickCircle,
      size: size,
      fontWeight: FontWeight.bold,
    );
  }
}

/// Badge vai trò người dùng.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.name, this.size = BadgeSize.compact});

  final String name;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBadge(
      label: name,
      color: cs.onSecondaryContainer,
      bulkIcon: AmazingIconBulk.personalcard,
      size: size,
      backgroundColor: cs.secondaryContainer.withValues(alpha: 0.65),
      borderColor: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

/// Badge bảo mật 2FA.
class TwoFactorBadge extends StatelessWidget {
  const TwoFactorBadge({super.key, this.size = BadgeSize.compact});

  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: '2FA',
      color: AppColor.green,
      bulkIcon: AmazingIconBulk.shieldTick,
      size: size,
    );
  }
}
