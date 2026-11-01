import 'package:flutter/material.dart';

import 'colors.dart';

enum Urgency { safe, soon, near, urgent, today, overdue, done }

class UrgencyInfo {
  const UrgencyInfo({
    required this.level,
    required this.color,
    required this.label,
    required this.glow,
  });
  final Urgency level;
  final Color color;
  final String label;
  final double glow; // 0..1 — how much the card should breathe
}

UrgencyInfo urgencyFor(DateTime? dueDate, {DateTime? now, bool closed = false}) {
  if (closed) {
    return const UrgencyInfo(
      level: Urgency.done,
      color: AppColors.success,
      label: 'Closed',
      glow: 0,
    );
  }
  if (dueDate == null) {
    return const UrgencyInfo(
      level: Urgency.safe,
      color: AppColors.textTertiary,
      label: 'No date',
      glow: 0,
    );
  }
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = target.difference(today).inDays;

  if (diff < 0) {
    return UrgencyInfo(
      level: Urgency.overdue,
      color: AppColors.danger,
      label: '${-diff}d overdue',
      glow: 1.0,
    );
  }
  if (diff == 0) {
    return const UrgencyInfo(
      level: Urgency.today,
      color: AppColors.danger,
      label: 'Due today',
      glow: 0.95,
    );
  }
  if (diff <= 3) {
    return UrgencyInfo(
      level: Urgency.urgent,
      color: AppColors.urgent,
      label: diff == 1 ? 'Tomorrow' : 'In $diff days',
      glow: 0.75,
    );
  }
  if (diff <= 7) {
    return UrgencyInfo(
      level: Urgency.near,
      color: AppColors.warning,
      label: 'In $diff days',
      glow: 0.45,
    );
  }
  if (diff <= 14) {
    return UrgencyInfo(
      level: Urgency.soon,
      color: AppColors.info,
      label: 'In $diff days',
      glow: 0.2,
    );
  }
  return UrgencyInfo(
    level: Urgency.safe,
    color: AppColors.textSecondary,
    label: 'In $diff days',
    glow: 0,
  );
}
