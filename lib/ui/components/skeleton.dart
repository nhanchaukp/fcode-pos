import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    required this.height,
    required this.widthFactor,
    this.radius = 8,
  });

  final double height;
  final double widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth.isFinite
            ? maxWidth * widthFactor
            : 140 * widthFactor;

        return SkeletonBox(
          width: width,
          height: height,
          radius: radius,
        );
      },
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 40, height: 40, radius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(height: 14, widthFactor: 0.62),
                  SizedBox(height: 8),
                  SkeletonLine(height: 12, widthFactor: 0.45),
                  SizedBox(height: 4),
                  SkeletonLine(height: 12, widthFactor: 0.35),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 20, height: 20, radius: 4),
          ],
        ),
      ),
    );
  }
}

class SkeletonGradientStatCard extends StatelessWidget {
  const SkeletonGradientStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonLine(height: 12, widthFactor: 0.42),
          SizedBox(height: 10),
          SkeletonLine(height: 24, widthFactor: 0.58),
        ],
      ),
    );
  }
}
