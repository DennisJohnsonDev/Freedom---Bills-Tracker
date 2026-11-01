import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../core/haptics.dart';

class NavTab {
  const NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Floating, blurred bottom nav with a pill that smoothly expands behind the
/// active tab — icon + label inside, springy motion.
class FreedomNavBar extends StatelessWidget {
  const FreedomNavBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<NavTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final activeWidth = (constraints.maxWidth - 16) * 0.42;
                  final inactiveWidth =
                      (constraints.maxWidth - 16 - activeWidth) /
                          (tabs.length - 1);
                  return Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        _NavCell(
                          tab: tabs[i],
                          active: i == index,
                          activeWidth: activeWidth,
                          inactiveWidth: inactiveWidth,
                          onTap: () {
                            if (i == index) return;
                            Haptics.selection();
                            onChanged(i);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.tab,
    required this.active,
    required this.activeWidth,
    required this.inactiveWidth,
    required this.onTap,
  });

  final NavTab tab;
  final bool active;
  final double activeWidth;
  final double inactiveWidth;
  final VoidCallback onTap;

  static const _kDur = Duration(milliseconds: 360);
  static const _kCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: _kDur,
      curve: _kCurve,
      width: active ? activeWidth : inactiveWidth,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: _kDur,
            curve: _kCurve,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: _kDur,
                  switchInCurve: _kCurve,
                  child: Icon(
                    tab.icon,
                    key: ValueKey('${tab.label}-$active'),
                    size: 20,
                    color: active
                        ? AppColors.accent
                        : AppColors.textTertiary,
                  ),
                ),
                // Smoothly expanding label — appears once the pill is wide enough.
                ClipRect(
                  child: AnimatedAlign(
                    duration: _kDur,
                    curve: _kCurve,
                    alignment: Alignment.centerLeft,
                    heightFactor: 1,
                    widthFactor: active ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        opacity: active ? 1 : 0,
                        child: Text(
                          tab.label,
                          style: t.labelLarge?.copyWith(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
