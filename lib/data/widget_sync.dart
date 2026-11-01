import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/format.dart';
import 'hive_init.dart';
import 'models/loan.dart';

/// Bridges Flutter loan data → native home-screen widget storage.
///
/// The native widget reads these keys from SharedPreferences (Android) and
/// renders accordingly. We push updates on app start and whenever the loans
/// or payments box changes.
class WidgetSync {
  WidgetSync._();

  static const _androidProviderClass = 'FreedomCountdownWidget';

  // Keys (must match Kotlin)
  static const _kHasLoans = 'has_loans';
  static const _kMonthsToFreedom = 'months_to_freedom';
  static const _kFreedomDateLabel = 'freedom_date_label';
  static const _kMonthlyOutflow = 'monthly_outflow';
  static const _kProgressPercent = 'progress_percent';
  static const _kNextDueLender = 'next_due_lender';
  static const _kNextDueLabel = 'next_due_label';
  static const _kUpdatedAt = 'updated_at';

  static bool _booted = false;
  static StreamSubscription? _loansSub;
  static StreamSubscription? _paymentsSub;
  static Timer? _debounce;

  /// Pushes a snapshot now and starts listening to box changes so future
  /// edits keep the widget current. Safe to call multiple times.
  static Future<void> boot() async {
    if (_booted) return;
    _booted = true;

    await refresh();

    _loansSub = HiveInit.loans.watch().listen((_) => _scheduleRefresh());
    _paymentsSub = HiveInit.payments.watch().listen((_) => _scheduleRefresh());
  }

  /// Coalesce burst writes into a single widget refresh.
  static void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), refresh);
  }

  /// Snapshots the current loan state into the widget's data store and
  /// asks the OS to repaint any installed widgets.
  static Future<void> refresh() async {
    try {
      final loans = HiveInit.loans.values.toList();
      final active = loans.where((l) => !l.isClosed && !l.archived).toList();
      final hasLoans = loans.isNotEmpty;

      int months = 0;
      DateTime? freedom;
      double monthly = 0;
      double totalRemaining = 0;
      double totalOriginal = 0;
      double totalPaid = 0;

      for (final l in loans) {
        if (l.archived) continue;
        totalOriginal += l.totalAmount;
        totalPaid += l.paidAmount;
        totalRemaining += l.remainingAmount;
      }
      for (final l in active) {
        monthly += l.emiAmount;
        if (l.emisRemaining > months) {
          months = l.emisRemaining;
          freedom = l.closureDate;
        }
      }

      final progress = totalOriginal == 0
          ? 0
          : ((totalPaid / totalOriginal) * 100).round().clamp(0, 100);

      // Soonest upcoming EMI (for the secondary line).
      Loan? next;
      for (final l in active) {
        final d = l.nextDueDate;
        if (d == null) continue;
        if (next == null) {
          next = l;
        } else {
          final nd = next.nextDueDate!;
          if (d.isBefore(nd)) next = l;
        }
      }

      await HomeWidget.saveWidgetData<bool>(_kHasLoans, hasLoans);
      await HomeWidget.saveWidgetData<int>(_kMonthsToFreedom, months);
      await HomeWidget.saveWidgetData<String>(
        _kFreedomDateLabel,
        freedom == null ? '' : 'free by ${Dates.monthYear(freedom)}',
      );
      await HomeWidget.saveWidgetData<String>(
        _kMonthlyOutflow,
        monthly == 0 ? '' : '${Money.inrCompact(monthly)} / mo',
      );
      await HomeWidget.saveWidgetData<int>(_kProgressPercent, progress.toInt());
      await HomeWidget.saveWidgetData<String>(
        _kNextDueLender,
        next?.lender ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _kNextDueLabel,
        next?.nextDueDate == null
            ? ''
            : 'next ${Dates.relative(next!.nextDueDate!)}',
      );
      await HomeWidget.saveWidgetData<String>(
        _kUpdatedAt,
        DateTime.now().toIso8601String(),
      );

      // Android-only — we don't ship an iOS widget extension yet.
      await HomeWidget.updateWidget(androidName: _androidProviderClass);
    } catch (e, st) {
      // Never let a widget update crash the app.
      debugPrint('WidgetSync.refresh failed: $e\n$st');
    }
  }

  static Future<void> dispose() async {
    await _loansSub?.cancel();
    await _paymentsSub?.cancel();
    _debounce?.cancel();
    _booted = false;
  }
}
