import 'dart:async';
import 'package:flutter/material.dart';

/// Delay for list items: the first 6 items appear one after another,
/// items further down (scrolled into view later) have no delay.
Duration staggerDelay(int index, {int stepMs = 45, int maxSteps = 6}) =>
    Duration(milliseconds: index < maxSteps ? index * stepMs : 0);

bool _reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// Fade + small slide up when the widget first appears.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.offsetY = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
  }
}

/// Scale + fade "pop" when the widget first appears (e.g. a new thumbnail).
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PopIn({super.key, required this.child, this.duration = const Duration(milliseconds: 260)});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final Animation<double> _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Number that counts up (0 -> value) and animates again whenever the value changes.
class CountUpText extends StatelessWidget {
  final double value;
  final String prefix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    this.prefix = '',
    this.decimals = 2,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return Text('$prefix${value.toStringAsFixed(decimals)}', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix${v.toStringAsFixed(decimals)}', style: style),
    );
  }
}
