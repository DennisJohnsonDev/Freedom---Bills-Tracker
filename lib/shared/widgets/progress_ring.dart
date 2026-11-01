import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 220,
    this.strokeWidth = 14,
    this.color = AppColors.accent,
    this.trackColor = AppColors.surfaceElevated,
    this.duration = const Duration(milliseconds: 1100),
    this.child,
    this.animationKey,
  });

  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Duration duration;
  final Widget? child;

  /// Change this value to restart the sweep animation from 0.
  /// Useful for re-animating each time the screen becomes visible.
  final Object? animationKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        key: animationKey == null ? null : ValueKey(animationKey),
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, p, __) => CustomPaint(
          painter: _RingPainter(
            progress: p,
            color: color,
            track: trackColor,
            stroke: strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep + 0.01,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}
