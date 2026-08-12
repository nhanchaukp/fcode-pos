import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';

/// Badge cơ bản với label, màu và icon — hỗ trợ chế độ 'filled', 'outlined', và 'ghost'.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.bulkIcon,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.size = BadgeSize.compact,
    this.variant = BadgeVariant.filled,
    this.isGhost = false,
    this.showIcon = true,
    this.backgroundColor,
    this.borderColor,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final BulkIconBuilder? bulkIcon;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final BadgeSize size;
  final BadgeVariant variant;

  /// Flag viết tắt cho mode ghost (`variant == BadgeVariant.ghost`).
  final bool isGhost;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? borderColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final bool isGhostMode = isGhost || variant == BadgeVariant.ghost;
    final resolvedFontSize = fontSize ?? AppBadgeTheme.fontSize(size);
    final resolvedPadding =
        padding ?? (isGhostMode ? EdgeInsets.zero : AppBadgeTheme.padding(size));
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
      decoration: isGhostMode
          ? null
          : BoxDecoration(
              color: backgroundColor ?? color.withValues(alpha: bgOpacity),
              borderRadius: BorderRadius.circular(resolvedRadius),
              border: variant == BadgeVariant.outlined
                  ? Border.all(color: borderColor ?? color, width: 1)
                  : Border.all(
                      color:
                          borderColor ?? color.withValues(alpha: borderOpacity),
                      width: 1,
                    ),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && (icon != null || bulkIcon != null)) ...[
            if (bulkIcon != null)
              bulkIcon!(
                size: iconSize,
                color: color,
                opacity: isGhostMode ? 1.0 : 0.4,
              )
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
