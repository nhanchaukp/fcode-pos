import 'package:flutter/material.dart';

/// Link-style button (icon + text) dùng chung để tái sử dụng.
/// Mục tiêu: đồng bộ màu icon và text theo theme.
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.iconSize = 14,
    this.gap = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  final Color? color;
  final double iconSize;
  final double gap;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.primary;
    final defaultStyle = Theme.of(context).textTheme.labelSmall;

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: effectiveColor),
            SizedBox(width: gap),
            Text(
              label,
              style: (defaultStyle ?? const TextStyle()).copyWith(
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

