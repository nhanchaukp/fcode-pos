import 'package:fcode_pos/config/app_color.dart';
import 'package:fcode_pos/enums.dart';
import 'package:flutter/material.dart';

class EnumBadge extends StatelessWidget {
  const EnumBadge({
    super.key,
    this.value,
    this.fallbackLabel,
    this.fallbackIcon = Icons.help_outline,
    this.fallbackColor = AppColor.gray,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 10,
    this.showIcon = true,
  });

  final LabeledIconEnum? value;
  final String? fallbackLabel;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = value?.color ?? fallbackColor;
    final label = value?.label ?? fallbackLabel ?? '--';
    final icon = value?.icon ?? fallbackIcon;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundOpacity = isDark ? 0.24 : 0.12;
    final borderOpacity = isDark ? 0.5 : 0.22;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
