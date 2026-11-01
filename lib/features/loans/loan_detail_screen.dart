import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/urgency.dart';
import '../../data/models/loan.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/urgency_pill.dart';
import '../add_loan/add_loan_screen.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(allLoansProvider);
    final loan = loans.cast<Loan?>().firstWhere(
          (l) => l?.id == widget.loanId,
          orElse: () => null,
        );
    if (loan == null) {
      return const Scaffold(body: Center(child: Text('Loan not found')));
    }

    final t = Theme.of(context).textTheme;
    final info = urgencyFor(loan.nextDueDate, closed: loan.isClosed);
    final accent = AppColors.loanAccent(loan.accentIndex);
    final repo = ref.read(loanRepositoryProvider);
    final allPayments = ref.watch(paymentsStreamProvider).maybeWhen(
          data: (p) => p,
          orElse: () => repo.paymentsFor(loan.id),
        );
    final payments = paymentsForLoan(allPayments, loan.id);

    Future<void> handleMarkPaid() async {
      Haptics.success();
      await repo.markPaid(loan);
      final updated = repo.byId(loan.id);
      if (updated != null && updated.isClosed) {
        _confetti.play();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.85),
          builder: (_) => _ClosedDialog(loan: updated),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddLoanScreen(existing: loan),
              fullscreenDialog: true,
            )),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2,
                color: AppColors.textSecondary),
            onPressed: () => _confirmDelete(context, loan, repo),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      loan.lender.substring(0, 1).toUpperCase(),
                      style: t.headlineLarge?.copyWith(color: accent),
                    ),
                  ),
                ),
                const Gap(14),
                Center(child: Text(loan.lender, style: t.headlineLarge)),
                const Gap(4),
                Center(
                  child: Text(
                    '${Money.inr(loan.emiAmount)} / month',
                    style: t.bodyMedium,
                  ),
                ),
                const Gap(28),
                Center(
                  child: ProgressRing(
                    progress: loan.progress,
                    color: accent,
                    size: 180,
                    strokeWidth: 11,
                    trackColor: AppColors.surfaceTop,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(loan.progress * 100).round()}%',
                          style: t.displaySmall
                              ?.copyWith(color: accent, fontSize: 38),
                        ),
                        const Gap(2),
                        Text(
                          '${loan.emisPaid} of ${loan.totalEmis} EMIs',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                if (!loan.isClosed)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      child: UrgencyPill(info: info),
                    ),
                  ),
                const Gap(24),
                _StatGrid(loan: loan, payments: payments.length),
                const Gap(16),
                if (loan.nextDueDate != null)
                  GlowCard(
                    glowColor: info.color,
                    glow: info.glow * 0.4,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.calendarClock,
                              color: info.color, size: 20),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Next EMI',
                                  style: t.bodySmall),
                              const Gap(2),
                              Text(
                                Dates.dayLong(loan.nextDueDate!),
                                style: t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              const Gap(2),
                              Text(
                                Dates.relative(loan.nextDueDate!),
                                style: t.bodySmall
                                    ?.copyWith(color: info.color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Gap(24),
                Text('Payment history', style: t.headlineSmall),
                const Gap(12),
                if (payments.isEmpty)
                  GlowCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No payments yet',
                        style: t.bodyMedium,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final p in payments.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlowCard(
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    Dates.dayLong(p.paidOn),
                                    style: t.bodyLarge,
                                  ),
                                ),
                                Text(
                                  Money.inr(p.amount),
                                  style: t.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (payments.length > 1)
                        TextButton.icon(
                          onPressed: () async {
                            Haptics.medium();
                            await repo.undoLastPayment(loan);
                          },
                          icon: const Icon(LucideIcons.undo2, size: 16),
                          label: const Text('Undo last payment'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                AppColors.accent,
                AppColors.success,
                AppColors.warning,
                AppColors.info,
              ],
            ),
          ),
          if (!loan.isClosed)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: PrimaryButton(
                icon: LucideIcons.check,
                label: 'Mark this EMI as paid',
                onPressed: handleMarkPaid,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Loan loan,
    dynamic repo,
  ) async {
    final t = Theme.of(context).textTheme;
    final yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete ${loan.lender}?',
                  style: t.headlineSmall,
                  textAlign: TextAlign.center),
              const Gap(8),
              Text(
                'This removes the loan and all its payment history. Can\'t be undone.',
                style: t.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(20),
              PrimaryButton(
                label: 'Delete',
                danger: true,
                icon: LucideIcons.trash2,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const Gap(10),
              PrimaryButton(
                label: 'Cancel',
                outlined: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) {
      await repo.delete(loan.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.loan, required this.payments});
  final Loan loan;
  final int payments;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget cell(String label, String value, {Color? color}) {
      return Expanded(
        child: GlowCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: t.labelSmall
                      ?.copyWith(color: AppColors.textTertiary)),
              const Gap(8),
              Text(
                value,
                style: t.headlineSmall?.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            cell('Remaining', Money.inrCompact(loan.remainingAmount)),
            const Gap(10),
            cell('Paid', Money.inrCompact(loan.paidAmount),
                color: AppColors.success),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            cell('EMIs left', '${loan.emisRemaining}'),
            const Gap(10),
            cell('Total', '${loan.totalEmis} mo'),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            cell('Started', Dates.dayLong(loan.firstDueDate)),
            const Gap(10),
            cell('Closes', Dates.monthYear(loan.closureDate)),
          ],
        ),
      ],
    );
  }
}

class _ClosedDialog extends StatelessWidget {
  const _ClosedDialog({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.partyPopper,
                color: AppColors.accent, size: 56)
                .animate()
                .scaleXY(begin: 0.6, end: 1, duration: 400.ms, curve: Curves.elasticOut),
            const Gap(16),
            Text('${loan.lender} is closed!',
                style: t.headlineMedium, textAlign: TextAlign.center),
            const Gap(8),
            Text(
              'One less weight. Keep going.',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            PrimaryButton(
              label: 'Nice 🎉',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
