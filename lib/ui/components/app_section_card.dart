import 'package:flutter/material.dart';

/// Card chứa section có header icon + tiêu đề + danh sách nội dung bên trong,
/// thiết kế đồng nhất theo style `_DetailCard` của màn hình InvoiceDetailScreen.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.headerTrailing,
    this.children,
    this.child,
    this.padding,
    this.margin = EdgeInsets.zero,
  }) : assert(
          children != null || child != null,
          'Either children or child must be provided',
        );

  final String title;
  final IconData icon;
  final Widget? headerTrailing;
  final List<Widget>? children;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerTrailingWidget = headerTrailing;
    final childWidget = child;
    final childrenWidgets = children;

    return Card(
      margin: margin,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ),
                if (headerTrailingWidget != null) headerTrailingWidget,
              ],
            ),
            const SizedBox(height: 12),
            if (childWidget != null) childWidget,
            if (childrenWidgets != null) ...childrenWidgets,
          ],
        ),
      ),
    );
  }
}
