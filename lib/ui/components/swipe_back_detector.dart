import 'package:flutter/material.dart';

/// Vuốt từ cạnh trái màn hình để quay lại (kiểu iOS).
class SwipeBackDetector extends StatefulWidget {
  const SwipeBackDetector({super.key, required this.onPop, required this.child});

  final VoidCallback onPop;
  final Widget child;

  @override
  State<SwipeBackDetector> createState() => _SwipeBackDetectorState();
}

class _SwipeBackDetectorState extends State<SwipeBackDetector> {
  static const _edgeWidth = 28.0;
  static const _triggerDistance = 64.0;

  double _dragOffset = 0;
  bool _tracking = false;

  void _onDragStart(DragStartDetails details) {
    _tracking = details.globalPosition.dx <= _edgeWidth;
    _dragOffset = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_tracking) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0, 120);
    });
  }

  void _resetDrag() {
    if (!_tracking && _dragOffset == 0) return;
    setState(() {
      _dragOffset = 0;
      _tracking = false;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_tracking) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset >= _triggerDistance || velocity > 300) {
      widget.onPop();
    }
    _resetDrag();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_dragOffset * 0.35, 0),
          child: widget.child,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _resetDrag,
          ),
        ),
      ],
    );
  }
}
