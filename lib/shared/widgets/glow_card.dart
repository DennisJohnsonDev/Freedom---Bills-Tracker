import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Premium "minimal but alive" card. Optionally breathes with [glow] (0..1).
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.glowColor,
    this.glow = 0,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.onTap,
    this.borderColor,
    this.background,
  });

  final Widget child;
  final Color? glowColor;
  final double glow;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.surfaceTop.withValues(alpha: 0.6),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: background ?? AppColors.surface,
            borderRadius: br,
            border: Border.all(
              color: borderColor ?? AppColors.border,
              width: 0.5,
            ),
            boxShadow: glow > 0 && glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withValues(alpha: 0.16 * glow),
                      blurRadius: 28 * glow,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
