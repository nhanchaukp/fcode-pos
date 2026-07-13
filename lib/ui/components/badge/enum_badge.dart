import 'package:fcode_pos/config/app_color.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/badge/app_badge.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:flutter/material.dart';

class EnumBadge extends StatelessWidget {
  const EnumBadge({
    super.key,
    this.value,
    this.fallbackLabel,
    this.fallbackIcon = Icons.help_outline,
    this.fallbackColor = AppColor.gray,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.size = BadgeSize.compact,
    this.showIcon = true,
  });

  final LabeledIconEnum? value;
  final String? fallbackLabel;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final BadgeSize size;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final resolvedBulkIcon = bulkIconFor(value);

    return AppBadge(
      label: value?.label ?? fallbackLabel ?? '--',
      color: value?.color ?? fallbackColor,
      icon: resolvedBulkIcon == null ? (value?.icon ?? fallbackIcon) : null,
      bulkIcon: resolvedBulkIcon,
      fontSize: fontSize,
      padding: padding,
      borderRadius: borderRadius,
      size: size,
      showIcon: showIcon,
    );
  }
}
