import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/haptics.dart';

/// Small circular icon button used in screen headers.
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.accent = false,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.accent : AppColors.surfaceElevated,
      shape: CircleBorder(
        side: BorderSide(
          color: accent ? Colors.transparent : AppColors.border,
          width: 0.5,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: accent ? AppColors.accentInk : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
