import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/urgency.dart';
import '../../data/models/loan.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/header_action.dart';
import '../../shared/widgets/urgency_pill.dart';
import '../add_loan/add_loan_screen.dart';
import 'loan_detail_screen.dart';

enum _Sort { dueDate, closingSoon, biggest }

final _sortProvider = StateProvider<_Sort>((_) => _Sort.dueDate);
final _showArchivedProvider = StateProvider<bool>((_) => false);

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allLoansProvider);
    final sort = ref.watch(_sortProvider);
    final showArchived = ref.watch(_showArchivedProvider);

    final visible = [
      ...all.where((l) => showArchived || (!l.isClosed && !l.archived)),
    ];

    switch (sort) {
      case _Sort.dueDate:
        visible.sort((a, b) {
          if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
          final ad = a.nextDueDate ?? DateTime(9999);
          final bd = b.nextDueDate ?? DateTime(9999);
          return ad.compareTo(bd);
        });
        break;
      case _Sort.closingSoon:
        visible.sort((a, b) => a.emisRemaining.compareTo(b.emisRemaining));
        break;
      case _Sort.biggest:
        visible
            .sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
        break;
    }

    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loans', style: t.headlineLarge),
                          const Gap(2),
                          Text(
                            '${all.where((l) => !l.isClosed && !l.archived).length} active • ${all.where((l) => l.isClosed).length} closed',
                            style: t.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    HeaderAction(
                      icon: LucideIcons.plus,
                      accent: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddLoanScreen(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SortChip(
                      label: 'Due date',
                      icon: LucideIcons.calendarClock,
                      active: sort == _Sort.dueDate,
                      onTap: () => ref.read(_sortProvider.notifier).state =
                          _Sort.dueDate,
                    ),
                    const Gap(8),
                    _SortChip(
                      label: 'Closing soonest',
                      icon: LucideIcons.target,
                      active: sort == _Sort.closingSoon,
                      onTap: () => ref.read(_sortProvider.notifier).state =
                          _Sort.closingSoon,
                    ),
                    const Gap(8),
                    _SortChip(
                      label: 'Biggest',
                      icon: LucideIcons.chartColumn,
                      active: sort == _Sort.biggest,
                      onTap: () => ref.read(_sortProvider.notifier).state =
                          _Sort.biggest,
                    ),
                    const Gap(8),
                    _SortChip(
                      label: showArchived ? 'All' : 'Show closed',
                      icon: showArchived
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff,
                      active: showArchived,
                      onTap: () => ref
                          .read(_showArchivedProvider.notifier)
                          .state = !showArchived,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(8)),
            if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nothing here yet',
                    style: t.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (_, i) => _LoanTile(loan: visible[i])
                      .animate(delay: (40 * i).ms)
                      .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? AppColors.accent : AppColors.textSecondary),
              const Gap(7),
              Text(
                label,
                style: t.labelLarge?.copyWith(
                  color:
                      active ? AppColors.accent : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final due = loan.nextDueDate;
    final info = urgencyFor(due, closed: loan.isClosed);
    final accent = AppColors.loanAccent(loan.accentIndex);

    return GlowCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
      ),
      glowColor: info.color,
      glow: info.glow * 0.4,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  loan.lender.substring(0, 1).toUpperCase(),
                  style: t.headlineSmall
                      ?.copyWith(color: accent, fontSize: 16),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.lender,
                      style: t.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Gap(2),
                    Text(
                      '${Money.inr(loan.emiAmount)} / month',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              UrgencyPill(info: info, dense: true),
            ],
          ),
          const Gap(16),
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
          const Gap(10),
          Row(
            children: [
              Text(
                '${loan.emisPaid}/${loan.totalEmis} paid',
                style: t.bodySmall,
              ),
              const Spacer(),
              Text(
                loan.isClosed
                    ? 'Closed'
                    : due == null
                        ? '—'
                        : 'next ${Dates.dayShort(due)}',
                style: t.bodySmall
                    ?.copyWith(color: info.color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
