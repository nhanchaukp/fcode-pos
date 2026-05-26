import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

const kNumberAnimDuration = Duration(milliseconds: 900);
const kNumberAnimStagger = Duration(milliseconds: 70);

class AnimatedStatText extends StatefulWidget {
  const AnimatedStatText({
    super.key,
    required this.value,
    required this.builder,
    this.duration = kNumberAnimDuration,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Widget Function(BuildContext context, double animatedValue) builder;

  @override
  State<AnimatedStatText> createState() => _AnimatedStatTextState();
}

class _AnimatedStatTextState extends State<AnimatedStatText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = _buildAnimation(0, widget.value);
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedStatText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _animation = _buildAnimation(_animation.value, widget.value);
      _controller.forward(from: 0);
    }
  }

  Animation<double> _buildAnimation(double begin, double end) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) {
      await _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => widget.builder(context, _animation.value),
    );
  }
}

class AnimatedCurrencyText extends StatelessWidget {
  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.style,
    this.delay = Duration.zero,
  });

  final int value;
  final TextStyle? style;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedStatText(
      value: value.toDouble(),
      delay: delay,
      builder: (context, animatedValue) {
        return Text(
          CurrencyHelper.formatCurrency(animatedValue.round()),
          style: style,
        );
      },
    );
  }
}

class AnimatedIntText extends StatelessWidget {
  const AnimatedIntText({
    super.key,
    required this.value,
    required this.style,
    this.delay = Duration.zero,
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration delay;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return AnimatedStatText(
      value: value.toDouble(),
      delay: delay,
      builder: (context, animatedValue) {
        return Text(
          '${animatedValue.round()}$suffix',
          style: style,
        );
      },
    );
  }
}

class AnimatedPercentText extends StatelessWidget {
  const AnimatedPercentText({
    super.key,
    required this.value,
    required this.style,
    this.delay = Duration.zero,
    this.decimals = 1,
    this.suffix = '%',
  });

  final double value;
  final TextStyle? style;
  final Duration delay;
  final int decimals;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return AnimatedStatText(
      value: value,
      delay: delay,
      builder: (context, animatedValue) {
        return Text(
          '${animatedValue.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}
