import 'dart:math';

import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

/// Background color for gradients, blur, etc.
const Color checkeredBackgroundColor = Color(0xFFFAFAFB);

/// Max height factor for background.
const double heightConstraintFactor = 0.5;

/// A custom widget that applies a checkered background pattern with gradient effects.
class CheckeredBackground extends StatelessWidget {
  final Widget child;

  const CheckeredBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CheckeredBackgroundPainter(),
      child: child,
    );
  }
}

/// A custom painter that draws a checkered background pattern with vertical and horizontal grid lines,
/// along with linear and radial gradient overlays for visual enhancement.
class CheckeredBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double gridSize = min(size.width * 0.1, 64);
    final double lineThickness = 0.75;
    final double heightConstraint = size.height * heightConstraintFactor;
    final Paint linePaint = Paint()
      ..color = Colors.grey.applyOpacity(0.3)
      ..strokeWidth = lineThickness;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, heightConstraint), linePaint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= heightConstraint; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Apply gradient overlays
    _drawRadialGradientOverlay(canvas, size);
    _drawLinearGradientOverlay(canvas, size, heightConstraint);
  }

  /// Draws a radial gradient overlay over the canvas to create a smooth blend effect.
  void _drawRadialGradientOverlay(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          checkeredBackgroundColor.applyOpacity(0.0),
          checkeredBackgroundColor.applyOpacity(0.4),
          checkeredBackgroundColor.applyOpacity(0.2),
          Colors.transparent,
        ],
        center: Alignment.center,
        radius: 2.0,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Draws a vertical gradient overlay over the canvas to enhance the checkered background's appearance.
  void _drawLinearGradientOverlay(
      Canvas canvas, Size size, double heightConstraint) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          checkeredBackgroundColor,
          checkeredBackgroundColor.applyOpacity(0.3),
          checkeredBackgroundColor.applyOpacity(0.5),
          checkeredBackgroundColor.applyOpacity(0.7),
          checkeredBackgroundColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, heightConstraint));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, heightConstraint), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
