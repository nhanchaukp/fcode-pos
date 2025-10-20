import 'package:fcode_pos/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// A widget that animates a connection line with a checkmark in the middle.
/// The left and right lines expand and contract based on the `show` state, with a tick appearing after a delay.
///
/// [show] - Controls whether the connection line animation and the tick are visible.
class ConnectionLine extends StatelessWidget {
  final bool show;

  const ConnectionLine({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.widthFactor(
        mobileFactor: 0.25,
        largeScreenFactor: 0.1,
      ),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          // Left sideline with smooth expansion
          AnimatedSideline(left: true, show: show),

          // Animated checkmark
          AnimatedCheckmark(show: show),

          // Right sideline with smooth expansion
          AnimatedSideline(left: false, show: show),
        ],
      ),
    );
  }
}

/// A widget that animates horizontal sidelines with a gradient effect.
/// Handles both visibility and width expansion smoothly.
///
/// [left] - Indicates whether the sideline is on the left side (true) or right side (false).
/// [show] - Controls the visibility and animation of the sideline.
class AnimatedSideline extends StatelessWidget {
  final bool left;
  final bool show;

  const AnimatedSideline({super.key, required this.left, required this.show});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(builder: (context, constraints) {
        return Align(
          alignment: !left ? Alignment.centerLeft : Alignment.centerRight,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 750),
            width: show ? constraints.maxWidth : 0,
            child: SizedBox(
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: left
                        ? [
                            const Color(0x26FE9567),
                            const Color(0xFFF02E65),
                          ]
                        : [
                            const Color(0xFFF02E65),
                            const Color(0x26FE9567),
                          ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// A widget that animates the checkmark icon's appearance with a fade-in effect.
///
/// [show] - Determines when the checkmark appears.
class AnimatedCheckmark extends StatelessWidget {
  final bool show;

  const AnimatedCheckmark({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x14F02E65),
          border: Border.all(color: const Color(0x80F02E65), width: 1.8),
        ),
        child: const Center(
          child: Icon(Icons.check, size: 15, color: Color(0xFFFD366E)),
        ),
      ),
    );
  }
}
