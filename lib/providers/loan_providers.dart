import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/hive_init.dart';
import '../data/loan_repository.dart';
import '../data/models/loan.dart';
import '../data/models/payment.dart';

final loanRepositoryProvider = Provider<LoanRepository>((_) => LoanRepository());

/// Tracks the current nav-bar tab.
final navIndexProvider = StateProvider<int>((_) => 0);

/// Increments every time the Home tab becomes visible — used as a key
/// to re-trigger the entrance animation of the freedom progress ring.
final homeVisitTickProvider = StateProvider<int>((_) => 0);

/// Same idea for the Insights chart.
final insightsVisitTickProvider = StateProvider<int>((_) => 0);

/// Emits the full list of payments whenever the box changes.
final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  late final StreamController<List<Payment>> controller;
  StreamSubscription? sub;

  void emit() {
    if (controller.isClosed) return;
    controller.add(HiveInit.payments.values.toList());
  }

  controller = StreamController<List<Payment>>(
    onListen: () {
      emit();
      sub = HiveInit.payments.watch().listen((_) => emit());
    },
    onCancel: () async {
      await sub?.cancel();
    },
  );

  return controller.stream;
});

List<Payment> paymentsForLoan(List<Payment> all, String loanId) {
  return all.where((p) => p.loanId == loanId).toList()
    ..sort((a, b) => b.paidOn.compareTo(a.paidOn));
}

/// Emits the full list of loans whenever the box changes.
final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  final repo = ref.watch(loanRepositoryProvider);
  late final StreamController<List<Loan>> controller;
  StreamSubscription<BoxEvent>? sub;

  void emit() {
    if (controller.isClosed) return;
    controller.add(repo.all());
  }

  controller = StreamController<List<Loan>>(
    onListen: () {
      emit();
      sub = HiveInit.loans.watch().listen((_) => emit());
    },
    onCancel: () async {
      await sub?.cancel();
    },
  );

  return controller.stream;
});

/// Cheap, synchronous read for derived selectors.
final allLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansStreamProvider).maybeWhen(
        data: (l) => l,
        orElse: () => const <Loan>[],
      );
});

final activeLoansProvider = Provider<List<Loan>>((ref) {
  return ref
      .watch(allLoansProvider)
      .where((l) => !l.isClosed && !l.archived)
      .toList();
});

/// Loans sorted by closest-due-date first (overdue → today → near → far).
final loansByDueProvider = Provider<List<Loan>>((ref) {
  final list = [...ref.watch(activeLoansProvider)];
  list.sort((a, b) {
    final ad = a.nextDueDate;
    final bd = b.nextDueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return list;
});

/// Loans sorted by EMIs remaining (closing-soonest first) — for "quick wins".
final loansByClosingSoonProvider = Provider<List<Loan>>((ref) {
  final list = [...ref.watch(activeLoansProvider)];
  list.sort((a, b) => a.emisRemaining.compareTo(b.emisRemaining));
  return list;
});

class FreedomSummary {
  const FreedomSummary({
    required this.totalRemaining,
    required this.totalPaid,
    required this.totalOriginal,
    required this.monthlyOutflow,
    required this.monthsTillFree,
    required this.freedomDate,
    required this.activeCount,
    required this.closedCount,
  });

  final double totalRemaining;
  final double totalPaid;
  final double totalOriginal;
  final double monthlyOutflow;
  final int monthsTillFree;
  final DateTime? freedomDate;
  final int activeCount;
  final int closedCount;

  double get overallProgress =>
      totalOriginal == 0 ? 0 : (totalPaid / totalOriginal).clamp(0.0, 1.0);

  bool get hasLoans => activeCount + closedCount > 0;
}

final freedomSummaryProvider = Provider<FreedomSummary>((ref) {
  final all = ref.watch(allLoansProvider);
  final active = all.where((l) => !l.isClosed && !l.archived).toList();
  final closed = all.where((l) => l.isClosed).toList();

  double totalRemaining = 0;
  double totalPaid = 0;
  double totalOriginal = 0;
  double monthlyOutflow = 0;
  int maxRemaining = 0;
  DateTime? freedom;

  for (final l in all) {
    if (l.archived) continue;
    totalOriginal += l.totalAmount;
    totalPaid += l.paidAmount;
    totalRemaining += l.remainingAmount;
  }
  for (final l in active) {
    monthlyOutflow += l.emiAmount;
    if (l.emisRemaining > maxRemaining) {
      maxRemaining = l.emisRemaining;
      freedom = l.closureDate;
    }
  }

  return FreedomSummary(
    totalRemaining: totalRemaining,
    totalPaid: totalPaid,
    totalOriginal: totalOriginal,
    monthlyOutflow: monthlyOutflow,
    monthsTillFree: maxRemaining,
    freedomDate: freedom,
    activeCount: active.length,
    closedCount: closed.length,
  );
});

/// Forward outflow projection (declines as loans close).
/// Returns enough months to cover every active loan's closure + 2 buffer
/// months, capped at 36.
final outflowProjectionProvider = Provider<List<MonthOutflow>>((ref) {
  final loans = ref.watch(activeLoansProvider);
  final now = DateTime.now();
  final maxRem =
      loans.fold<int>(0, (m, l) => l.emisRemaining > m ? l.emisRemaining : m);
  final horizon = (maxRem + 2).clamp(12, 36);
  final months = <MonthOutflow>[];
  for (var i = 0; i < horizon; i++) {
    final m = DateTime(now.year, now.month + i, 1);
    double total = 0;
    final closing = <String>[];
    for (final l in loans) {
      if (l.emisPaid + i < l.totalEmis) {
        total += l.emiAmount;
        if (l.emisPaid + i == l.totalEmis - 1) closing.add(l.lender);
      }
    }
    months.add(MonthOutflow(month: m, amount: total, closing: closing));
  }
  return months;
});

class MonthOutflow {
  const MonthOutflow({
    required this.month,
    required this.amount,
    this.closing = const [],
  });
  final DateTime month;
  final double amount;

  /// Names of loans that close at the end of this month.
  final List<String> closing;
}
