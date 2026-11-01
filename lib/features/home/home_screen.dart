import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/urgency.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/animated_counter.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/header_action.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/urgency_pill.dart';
import '../add_loan/add_loan_screen.dart';
import '../loans/loan_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(freedomSummaryProvider);
    final upcoming = ref.watch(loansByDueProvider);
    final closingSoon = ref.watch(loansByClosingSoonProvider);
    final ringKey = ref.watch(homeVisitTickProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _Greeting(summary: summary)),
            if (!summary.hasLoans)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else ...[
              SliverToBoxAdapter(child: _FreedomHero(summary: summary, ringKey: ringKey)),
              const SliverToBoxAdapter(child: Gap(28)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Upcoming',
                    subtitle:
                        '${upcoming.length} payment${upcoming.length == 1 ? '' : 's'} ahead',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverList.separated(
                  itemCount: upcoming.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) => _UpcomingTile(loan: upcoming[i])
                      .animate(delay: (60 * i).ms)
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Closing soonest',
                    subtitle: 'Quick wins — kill these first',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: closingSoon.length.clamp(0, 3),
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) =>
                      _ClosingSoonTile(loan: closingSoon[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.summary});
  final FreedomSummary summary;

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still up?';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border, width: 0.5),
                    image: const DecorationImage(
                      image: AssetImage(
                          'assets/logo/freedom_app_logo_raw.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _salutation,
                        style: t.bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      const Gap(2),
                      Text('Freedom', style: t.headlineLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (summary.hasLoans) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.flame,
                      size: 14, color: AppColors.urgent),
                  const Gap(6),
                  Text(
                    Money.inrCompact(summary.monthlyOutflow),
                    style: t.labelLarge?.copyWith(fontSize: 13),
                  ),
                  const Gap(4),
                  Text('/mo',
                      style: t.bodySmall
                          ?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Gap(8),
            HeaderAction(
              icon: LucideIcons.plus,
              accent: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddLoanScreen(),
                fullscreenDialog: true,
              )),
            ),
          ],
        ],
      ),
    );
  }
}

class _FreedomHero extends StatelessWidget {
  const _FreedomHero({required this.summary, required this.ringKey});
  final FreedomSummary summary;
  final int ringKey;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final months = summary.monthsTillFree;
    final years = months ~/ 12;
    final remMonths = months % 12;

    String timeLabel;
    if (months == 0) {
      timeLabel = 'You are free 🎉';
    } else if (years == 0) {
      timeLabel = '$months month${months == 1 ? '' : 's'} to freedom';
    } else if (remMonths == 0) {
      timeLabel = '$years year${years == 1 ? '' : 's'} to freedom';
    } else {
      timeLabel = '${years}y ${remMonths}mo to freedom';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlowCard(
        glowColor: AppColors.accent,
        glow: 0.35,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ProgressRing(
                  progress: summary.overallProgress,
                  size: 230,
                  strokeWidth: 12,
                  color: AppColors.accent,
                  trackColor: AppColors.surfaceTop,
                  animationKey: ringKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'IN',
                        style: t.labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      const Gap(6),
                      AnimatedCounter(
                        value: months,
                        style: t.displayLarge!.copyWith(
                          color: AppColors.accent,
                          fontSize: 80,
                        ),
                      ),
                      Text(
                        months == 1 ? 'month' : 'months',
                        style: t.bodyLarge
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(20),
            Text(timeLabel, style: t.headlineSmall),
            if (summary.freedomDate != null) ...[
              const Gap(4),
              Text(
                'free by ${Dates.monthYear(summary.freedomDate!)}',
                style: t.bodyMedium?.copyWith(color: AppColors.textTertiary),
              ),
            ],
            const Gap(20),
            Container(
              height: 1,
              color: AppColors.border,
            ),
            const Gap(16),
            Row(
              children: [
                _HeroMetric(
                  label: 'Paid',
                  value: Money.inrCompact(summary.totalPaid),
                  color: AppColors.success,
                ),
                _HeroDivider(),
                _HeroMetric(
                  label: 'Remaining',
                  value: Money.inrCompact(summary.totalRemaining),
                  color: AppColors.textPrimary,
                ),
                _HeroDivider(),
                _HeroMetric(
                  label: 'Loans',
                  value: '${summary.activeCount}',
                  sub: summary.closedCount > 0
                      ? '${summary.closedCount} closed'
                      : null,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 32, color: AppColors.border);
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });
  final String label;
  final String value;
  final Color color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: t.labelSmall?.copyWith(color: AppColors.textTertiary),
          ),
          const Gap(6),
          Text(
            value,
            style: t.headlineMedium?.copyWith(color: color, fontSize: 20),
          ),
          if (sub != null) ...[
            const Gap(2),
            Text(
              sub!,
              style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.loan});
  final dynamic loan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final due = loan.nextDueDate;
    final info = urgencyFor(due);
    final accent = AppColors.loanAccent(loan.accentIndex);

    return GlowCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
      ),
      glowColor: info.color,
      glow: info.glow * 0.5,
      borderColor:
          info.glow > 0.6 ? info.color.withValues(alpha: 0.4) : AppColors.border,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              loan.lender.substring(0, 1).toUpperCase(),
              style: t.headlineSmall?.copyWith(color: accent),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.lender,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Gap(3),
                Text(
                  due == null ? '—' : Dates.dayLong(due),
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.inr(loan.emiAmount),
                style: t.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(4),
              UrgencyPill(info: info, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosingSoonTile extends StatelessWidget {
  const _ClosingSoonTile({required this.loan});
  final dynamic loan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = AppColors.loanAccent(loan.accentIndex);
    final remaining = loan.emisRemaining;

    return GlowCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loan.lender,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$remaining left',
                style: t.bodyMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.surfaceTop),
                FractionallySizedBox(
                  widthFactor: loan.progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.5),
                          accent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Text(
                '${(loan.progress * 100).round()}% done',
                style: t.bodySmall,
              ),
              const Spacer(),
              Text(
                'closes ${Dates.monthYear(loan.closureDate)}',
                style: t.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(LucideIcons.sparkles,
                size: 36, color: AppColors.accent),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.05, duration: 1800.ms),
          const Gap(24),
          Text('Start your freedom journey',
              style: t.headlineMedium, textAlign: TextAlign.center),
          const Gap(8),
          Text(
            'Add your first loan to see the countdown to debt-free.',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentInk,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AddLoanScreen(),
              fullscreenDialog: true,
            )),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add your first loan'),
          ),
        ],
      ),
    );
  }
}
