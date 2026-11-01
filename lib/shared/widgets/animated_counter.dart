import 'package:flutter/material.dart';

/// Smoothly tweens between integer values. Used for the freedom hero number.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
    this.suffix,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (_, v, __) {
        final n = v.round();
        return Text(
          suffix == null ? '$n' : '$n$suffix',
          style: style,
        );
      },
    );
  }
}
