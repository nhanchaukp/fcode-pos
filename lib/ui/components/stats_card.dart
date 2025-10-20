import 'package:fcode_pos/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class StatsCards extends StatelessWidget {
  final List<StatCard> cards;
  const StatsCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, // ✅ 2 card mỗi dòng
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2, // chỉnh tỷ lệ ngang/dọc (2.3–2.5 đẹp)
        children: cards,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? subtitleColor;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.subtitleColor,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = theme.colorScheme.surfaceContainerLowest;
    final iconColor = theme.colorScheme.onSurfaceVariant;
    final mainTextColor = textColor ?? theme.colorScheme.onSurface;

    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = context.isExtraWideScreen
          ? constraints.maxWidth.clamp(0, 350)
          : constraints.maxWidth;

      return SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 0,
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEDEDF0), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor ?? Colors.greenAccent.shade200,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
