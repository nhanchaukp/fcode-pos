import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge_twotone_icon.dart';
import 'package:flutter/material.dart';

/// Badge cơ bản với label, màu và icon — dùng chung cho mọi badge tuỳ chỉnh.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.twotoneIcon,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.size = BadgeSize.compact,
    this.showIcon = true,
    this.backgroundColor,
    this.borderColor,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final TwotoneIconBuilder? twotoneIcon;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final BadgeSize size;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? borderColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final resolvedFontSize = fontSize ?? AppBadgeTheme.fontSize(size);
    final resolvedPadding = padding ?? AppBadgeTheme.padding(size);
    final resolvedRadius = AppBadgeTheme.borderRadius(
      context,
      size: size,
      override: borderRadius,
    );
    final bgOpacity = AppBadgeTheme.backgroundOpacity(context);
    final borderOpacity = AppBadgeTheme.borderOpacity(context);
    final iconSize = resolvedFontSize + 2;

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && (icon != null || twotoneIcon != null)) ...[
            if (twotoneIcon != null)
              twotoneIcon!(size: iconSize, color: color, opacity: 0.45)
            else
              Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: resolvedFontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
