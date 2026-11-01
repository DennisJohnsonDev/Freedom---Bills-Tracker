import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../data/models/loan.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/section_header.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  double _extra = 0;
  final _spendCtrl = TextEditingController();
  double _spend = 0;

  @override
  void dispose() {
    _spendCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(freedomSummaryProvider);
    final loans = ref.watch(activeLoansProvider);
    final t = Theme.of(context).textTheme;

    if (!summary.hasLoans) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Add a loan to start planning',
              style: t.bodyMedium,
            ),
          ),
        ),
      );
    }

    final extraImpact = _calcExtraImpact(loans, _extra);
    final spendImpact = _calcSpendImpact(loans, summary.monthlyOutflow, _spend);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('Planner', style: t.headlineLarge),
            const Gap(2),
            Text('See what every rupee does to your freedom',
                style: t.bodyMedium),
            const Gap(24),

            // ---- Extra payment simulator ----
            SectionHeader(
              title: 'What if you pay extra?',
              subtitle: 'Drag the slider to see how much sooner you\'re free',
            ),
            _ExtraPaymentCard(
              extra: _extra,
              max: _maxSensibleExtra(summary.monthlyOutflow),
              impact: extraImpact,
              onChanged: (v) => setState(() => _extra = v),
            ),
            const Gap(28),

            // ---- Spend check ----
            SectionHeader(
              title: 'Spend check',
              subtitle: 'Type an amount you\'re thinking of spending',
            ),
            _SpendCheckCard(
              controller: _spendCtrl,
              amount: _spend,
              impact: spendImpact,
              onChanged: (v) => setState(() => _spend = v),
            ),
            const Gap(28),

            // ---- All upcoming EMIs (calendar peek) ----
            SectionHeader(
              title: 'Upcoming spend, next 60 days',
              subtitle: 'Every EMI that hits your account',
            ),
            _UpcomingTimeline(loans: loans),
          ],
        ),
      ),
    );
  }

  double _maxSensibleExtra(double monthlyOutflow) {
    // Cap slider at ~1.5× current outflow so the scale stays useful.
    final cap = (monthlyOutflow * 1.5).ceilToDouble();
    return cap < 5000 ? 5000 : cap;
  }

  /// Effect of paying [extra] each month: applied to the longest-running loan
  /// (canonical "avalanche by tenure"). Returns months saved + new freedom date.
  _ExtraImpact _calcExtraImpact(List<Loan> loans, double extra) {
    if (loans.isEmpty || extra <= 0) {
      return _ExtraImpact(monthsSaved: 0, totalSaved: 0, freedomDate: null);
    }
    // Find the longest loan — that determines current freedom.
    final longest = [...loans]
      ..sort((a, b) => b.emisRemaining.compareTo(a.emisRemaining));
    final target = longest.first;
    // Extra ₹/month → effective EMI increases by `extra` for that loan.
    // New months = remainingBalance / (emi + extra), rounded up.
    final newMonths =
        (target.remainingAmount / (target.emiAmount + extra)).ceil();
    final saved = (target.emisRemaining - newMonths).clamp(0, target.emisRemaining);
    final newFree = _addMonths(
      DateTime.now(),
      (target.emisRemaining - saved),
    );
    final moneySaved = extra * 0; // No interest model — neutral.
    return _ExtraImpact(
      monthsSaved: saved,
      totalSaved: moneySaved,
      freedomDate: newFree,
    );
  }

  _SpendImpact _calcSpendImpact(
      List<Loan> loans, double monthlyOutflow, double spend) {
    if (spend <= 0 || loans.isEmpty) {
      return const _SpendImpact(daysDelayed: 0, monthsCouldShorten: 0);
    }
    // Days of debt service this could have funded.
    final days = (spend / (monthlyOutflow / 30)).ceil();
    // If applied as prepay on longest loan, how many months sooner?
    final longest = [...loans]
      ..sort((a, b) => b.emisRemaining.compareTo(a.emisRemaining));
    final target = longest.first;
    final monthsShorter = (spend / target.emiAmount).floor();
    return _SpendImpact(
      daysDelayed: days,
      monthsCouldShorten: monthsShorter,
    );
  }
}

DateTime _addMonths(DateTime base, int months) {
  final year = base.year + ((base.month - 1 + months) ~/ 12);
  final month = ((base.month - 1 + months) % 12) + 1;
  return DateTime(year, month, base.day);
}

class _ExtraImpact {
  _ExtraImpact({
    required this.monthsSaved,
    required this.totalSaved,
    required this.freedomDate,
  });
  final int monthsSaved;
  final double totalSaved;
  final DateTime? freedomDate;
}

class _SpendImpact {
  const _SpendImpact({
    required this.daysDelayed,
    required this.monthsCouldShorten,
  });
  final int daysDelayed;
  final int monthsCouldShorten;
}

class _ExtraPaymentCard extends StatelessWidget {
  const _ExtraPaymentCard({
    required this.extra,
    required this.max,
    required this.impact,
    required this.onChanged,
  });
  final double extra;
  final double max;
  final _ExtraImpact impact;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlowCard(
      glowColor: AppColors.accent,
      glow: extra > 0 ? 0.4 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXTRA PER MONTH',
                        style: t.labelSmall
                            ?.copyWith(color: AppColors.textTertiary)),
                    const Gap(6),
                    Text(
                      Money.inr(extra),
                      style: t.displaySmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
              ),
              if (impact.monthsSaved > 0)
                _SavedBadge(months: impact.monthsSaved),
            ],
          ),
          const Gap(8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceTop,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: extra.clamp(0, max),
              min: 0,
              max: max,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Money.inr(0), style: t.bodySmall),
              Text(Money.inrCompact(max), style: t.bodySmall),
            ],
          ),
          const Gap(20),
          Container(height: 0.5, color: AppColors.border),
          const Gap(18),
          if (extra <= 0)
            Text(
              'Drag right to simulate paying more each month.',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            )
          else
            Column(
              children: [
                _ImpactRow(
                  icon: LucideIcons.calendarCheck,
                  label: 'Months saved',
                  value: '${impact.monthsSaved}',
                  color: AppColors.success,
                ),
                const Gap(12),
                if (impact.freedomDate != null)
                  _ImpactRow(
                    icon: LucideIcons.flag,
                    label: 'New freedom date',
                    value: Dates.monthYear(impact.freedomDate!),
                    color: AppColors.accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({required this.months});
  final int months;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.trendingDown,
              size: 12, color: AppColors.success),
          const Gap(4),
          Text(
            '−$months mo',
            style: t.labelMedium?.copyWith(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(months)).scaleXY(
        begin: 0.85, end: 1, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const Gap(12),
        Expanded(child: Text(label, style: t.bodyMedium)),
        Text(
          value,
          style: t.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SpendCheckCard extends StatelessWidget {
  const _SpendCheckCard({
    required this.controller,
    required this.amount,
    required this.impact,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double amount;
  final _SpendImpact impact;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final danger = amount >= 5000;
    final color = danger ? AppColors.danger : AppColors.warning;

    return GlowCard(
      glowColor: amount > 0 ? color : null,
      glow: amount > 0 ? 0.4 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS PURCHASE',
              style: t.labelSmall?.copyWith(color: AppColors.textTertiary)),
          const Gap(10),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            style: t.displaySmall?.copyWith(fontSize: 36, color: color),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              prefixText: '₹  ',
              prefixStyle:
                  t.displaySmall?.copyWith(fontSize: 36, color: color),
              hintText: '0',
              hintStyle: t.displaySmall
                  ?.copyWith(fontSize: 36, color: AppColors.textQuaternary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v) ?? 0;
              onChanged(parsed);
            },
          ),
          const Gap(8),
          Container(height: 0.5, color: AppColors.border),
          const Gap(18),
          if (amount <= 0)
            Text(
              'Type an amount to see what it costs you in freedom.',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        danger
                            ? LucideIcons.triangleAlert
                            : LucideIcons.info,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            impact.monthsCouldShorten > 0
                                ? 'Could shave ${impact.monthsCouldShorten} month${impact.monthsCouldShorten == 1 ? '' : 's'} off your freedom'
                                : 'Equal to ${impact.daysDelayed} day${impact.daysDelayed == 1 ? '' : 's'} of EMI outflow',
                            style: t.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                          const Gap(2),
                          Text(
                            'If prepaid instead of spent',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.messageCircleQuestion,
                          size: 16, color: color),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          danger
                              ? 'Still want it?'
                              : 'Worth it?',
                          style: t.bodyMedium?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingTimeline extends StatelessWidget {
  const _UpcomingTimeline({required this.loans});
  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 60));

    // Collect every EMI due in horizon.
    final items = <_Hit>[];
    for (final l in loans) {
      var d = l.nextDueDate;
      var emiIndex = l.emisPaid + 1;
      while (d != null && d.isBefore(horizon) && emiIndex <= l.totalEmis) {
        if (d.isAfter(now.subtract(const Duration(days: 1)))) {
          items.add(_Hit(loan: l, date: d, emiIndex: emiIndex));
        }
        emiIndex++;
        d = _addMonthsLoan(l.firstDueDate, emiIndex - 1);
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return GlowCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No EMIs in the next 60 days', style: t.bodyMedium),
        ),
      );
    }

    final total = items.fold<double>(0, (s, h) => s + h.loan.emiAmount);

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${items.length} payment${items.length == 1 ? '' : 's'}',
                  style: t.bodyMedium,
                ),
              ),
              Text(
                Money.inrCompact(total),
                style: t.headlineSmall?.copyWith(color: AppColors.urgent),
              ),
            ],
          ),
          const Gap(14),
          for (var i = 0; i < items.length; i++) ...[
            _TimelineRow(item: items[i]),
            if (i < items.length - 1) ...[
              const Gap(10),
              Container(
                margin: const EdgeInsets.only(left: 19),
                height: 0.5,
                color: AppColors.border,
              ),
              const Gap(10),
            ],
          ],
        ],
      ),
    );
  }
}

DateTime _addMonthsLoan(DateTime base, int months) {
  final year = base.year + ((base.month - 1 + months) ~/ 12);
  final month = ((base.month - 1 + months) % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = base.day > lastDay ? lastDay : base.day;
  return DateTime(year, month, day);
}

class _Hit {
  _Hit({required this.loan, required this.date, required this.emiIndex});
  final Loan loan;
  final DateTime date;
  final int emiIndex;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item});
  final _Hit item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = AppColors.loanAccent(item.loan.accentIndex);
    return Row(
      children: [
        Container(
          width: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                Dates.weekday(item.date).toUpperCase(),
                style: t.labelSmall
                    ?.copyWith(color: AppColors.textTertiary, fontSize: 9),
              ),
              Text(
                '${item.date.day}',
                style: t.headlineSmall?.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.loan.lender,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                'EMI ${item.emiIndex} of ${item.loan.totalEmis}',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          Money.inr(item.loan.emiAmount),
          style: t.bodyLarge?.copyWith(color: accent, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
