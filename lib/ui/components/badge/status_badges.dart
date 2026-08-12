import 'package:amazing_icons/bulk.dart';
import 'package:fcode_pos/config/app_color.dart';
import 'package:fcode_pos/ui/components/badge/app_badge.dart';
import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';

/// Badge trạng thái kích hoạt (hoạt động / vô hiệu, active / inactive, ...).
class ActiveStatusBadge extends StatelessWidget {
  const ActiveStatusBadge({
    super.key,
    required this.isActive,
    this.activeLabel = 'Hoạt động',
    this.inactiveLabel = 'Không hoạt động',
    this.activeColor = AppColor.green,
    this.inactiveColor = AppColor.gray,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
    this.showIcon = false,
  });

  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeColor;
  final Color inactiveColor;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: isActive ? activeLabel : inactiveLabel,
      color: isActive ? activeColor : inactiveColor,
      showIcon: showIcon,
      size: size,
      variant: variant,
      isGhost: isGhost,
      fontWeight: FontWeight.w600,
    );
  }
}

/// Badge trạng thái phê duyệt (Đã duyệt / Chưa duyệt).
class ApprovalStatusBadge extends StatelessWidget {
  const ApprovalStatusBadge({
    super.key,
    required this.isApproved,
    this.approvedLabel = 'Đã duyệt',
    this.pendingLabel = 'Chưa duyệt',
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final bool isApproved;
  final String approvedLabel;
  final String pendingLabel;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isApproved ? cs.primary : cs.onSurfaceVariant;
    final icon =
        isApproved ? Icons.check_circle_outline : Icons.pending_outlined;

    return AppBadge(
      label: isApproved ? approvedLabel : pendingLabel,
      color: color,
      icon: icon,
      size: size,
      variant: variant,
      isGhost: isGhost,
    );
  }
}

/// Badge hiển thị danh mục / nhãn màu tùy chọn.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: label,
      color: color,
      icon: icon,
      showIcon: icon != null,
      size: size,
      variant: variant,
      isGhost: isGhost,
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
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final BulkIconBuilder icon;
  final String label;
  final Color? color;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBadge(
      label: label,
      color: color ?? cs.primary,
      bulkIcon: icon,
      size: size,
      variant: variant,
      isGhost: isGhost,
    );
  }
}

/// Badge trạng thái vị trí truy cập (success / khác).
class LocationStatusBadge extends StatelessWidget {
  const LocationStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final String? status;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

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
      variant: variant,
      isGhost: isGhost,
    );
  }
}

/// Badge hiển thị trạng thái hết hạn.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.isExpired,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final bool isExpired;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: isExpired ? 'Đã hết hạn' : 'Còn hiệu lực',
      color: isExpired ? AppColor.red : AppColor.green,
      bulkIcon: isExpired ? AmazingIconBulk.danger : AmazingIconBulk.tickCircle,
      size: size,
      variant: variant,
      isGhost: isGhost,
      fontWeight: FontWeight.bold,
    );
  }
}

/// Badge vai trò người dùng.
class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.name,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final String name;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBadge(
      label: name,
      color: cs.onSecondaryContainer,
      bulkIcon: AmazingIconBulk.personalcard,
      size: size,
      variant: variant,
      isGhost: isGhost,
      backgroundColor: cs.secondaryContainer.withValues(alpha: 0.65),
      borderColor: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

/// Badge bảo mật 2FA.
class TwoFactorBadge extends StatelessWidget {
  const TwoFactorBadge({
    super.key,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: '2FA',
      color: AppColor.green,
      bulkIcon: AmazingIconBulk.shieldTick,
      size: size,
      variant: variant,
      isGhost: isGhost,
    );
  }
}

/// Badge hiển thị số ngày còn lại (hoặc hết hạn) cho Account Slot.
class DaysRemainingBadge extends StatelessWidget {
  const DaysRemainingBadge({
    super.key,
    required this.days,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
  });

  final int days;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (days <= 0) {
      color = Colors.red;
      label = 'Hết hạn';
    } else if (days <= 3) {
      color = Colors.orange;
      label = '$days ngày';
    } else if (days <= 7) {
      color = Colors.amber.shade700;
      label = '$days ngày';
    } else {
      color = Colors.green;
      label = '$days ngày';
    }

    return AppBadge(
      label: label,
      color: color,
      showIcon: false,
      size: size,
      variant: variant,
      isGhost: isGhost,
      fontWeight: FontWeight.w700,
    );
  }
}
