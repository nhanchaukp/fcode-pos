import 'package:flutter/material.dart';

/// A flexible icon widget that can automatically spin when in a loading state.
/// Perfect for use inside buttons or action icons.
class LoadingIcon extends StatefulWidget {
  /// Icon to display when not loading.
  final IconData icon;

  /// Whether the icon is currently loading (spinning).
  final bool loading;

  /// Icon color.
  final Color? color;

  /// Icon size.
  final double size;

  /// Rotation speed (duration of one spin).
  final Duration spinDuration;

  /// Optional alignment.
  final Alignment alignment;

  const LoadingIcon({
    super.key,
    required this.icon,
    this.loading = false,
    this.color,
    this.size = 20,
    this.spinDuration = const Duration(seconds: 1),
    this.alignment = Alignment.center,
  });

  @override
  State<LoadingIcon> createState() => _LoadingIconState();
}

class _LoadingIconState extends State<LoadingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.spinDuration,
    );

    if (widget.loading) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LoadingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.loading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: widget.loading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.color ??
                      Theme.of(context).iconTheme.color ??
                      Colors.blue,
                ),
              ),
            )
          : Icon(
              widget.icon,
              size: widget.size,
              color: widget.color ?? Theme.of(context).iconTheme.color,
            ),
    );
  }
}
