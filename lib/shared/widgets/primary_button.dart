import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/haptics.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.danger = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool danger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final bg = outlined
        ? Colors.transparent
        : (danger ? AppColors.danger : AppColors.accent);
    final fg = outlined
        ? AppColors.textPrimary
        : (danger ? Colors.white : AppColors.accentInk);

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
        ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled
              ? null
              : () {
                  Haptics.light();
                  onPressed!();
                },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: outlined
                  ? Border.all(color: AppColors.border, width: 0.5)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
