import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/creator_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(freedomSummaryProvider);
    final projection = ref.watch(outflowProjectionProvider);
    final closingSoon = ref.watch(loansByClosingSoonProvider);
    final chartTick = ref.watch(insightsVisitTickProvider);

    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('Insights', style: t.headlineLarge),
            const Gap(2),
            Text('Patterns that move the needle', style: t.bodyMedium),
            const Gap(20),
            if (!summary.hasLoans)
              GlowCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Add a loan to unlock insights.',
                    style: t.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              _OutflowChartCard(projection: projection, tick: chartTick),
              const Gap(20),
              SectionHeader(
                title: 'Quick win',
                subtitle: 'Close this one and feel the freedom',
              ),
              if (closingSoon.isNotEmpty)
                _QuickWinCard(loan: closingSoon.first),
              const Gap(20),
              SectionHeader(title: 'Big picture'),
              GlowCard(
                child: Column(
                  children: [
                    _BigRow(
                      label: 'Total borrowed',
                      value: Money.inrCompact(summary.totalOriginal),
                    ),
                    const Gap(14),
                    Container(height: 0.5, color: AppColors.border),
                    const Gap(14),
                    _BigRow(
                      label: 'Paid so far',
                      value: Money.inrCompact(summary.totalPaid),
                      color: AppColors.success,
                    ),
                    const Gap(14),
                    Container(height: 0.5, color: AppColors.border),
                    const Gap(14),
                    _BigRow(
                      label: 'Still to go',
                      value: Money.inrCompact(summary.totalRemaining),
                      color: AppColors.urgent,
                    ),
                  ],
                ),
              ),
            ],
            const Gap(32),
            const CreatorCard(),
          ],
        ),
      ),
    );
  }
}

class _OutflowChartCard extends StatelessWidget {
  const _OutflowChartCard({required this.projection, required this.tick});
  final List<MonthOutflow> projection;
  final int tick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final maxV = projection.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final first = projection.first.amount;
    final last = projection.last.amount;
    final dropPct =
        first == 0 ? 0 : (((first - last) / first) * 100).round();

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT ${projection.length} MONTHS',
                      style: t.labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                    const Gap(6),
                    Text('Monthly outflow', style: t.headlineSmall),
                  ],
                ),
              ),
              if (dropPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
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
                        '−$dropPct%',
                        style: t.labelMedium?.copyWith(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(4),
          Text(
            last < first
                ? 'Drops from ${Money.inrCompact(first)} → ${Money.inrCompact(last)}'
                : 'Steady at ${Money.inrCompact(first)}',
            style: t.bodySmall,
          ),
          const Gap(24),
          SizedBox(
            height: 200,
            child: _AreaChart(
              key: ValueKey(tick),
              projection: projection,
              maxY: maxV * 1.18,
            ),
          ),
          const Gap(12),
          _ClosureLegend(projection: projection),
        ],
      ),
    );
  }
}

class _AreaChart extends StatelessWidget {
  const _AreaChart({
    super.key,
    required this.projection,
    required this.maxY,
  });
  final List<MonthOutflow> projection;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final spots = [
      for (var i = 0; i < projection.length; i++)
        FlSpot(i.toDouble(), projection[i].amount),
    ];
    // Indices where a loan closes (label-worthy event).
    final closureIndices = [
      for (var i = 0; i < projection.length; i++)
        if (projection[i].closing.isNotEmpty) i,
    ];

    return LineChart(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withValues(alpha: 0.6),
            strokeWidth: 0.5,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  v == 0 ? '' : Money.inrCompact(v),
                  style: t.labelSmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (projection.length / 6).floorToDouble().clamp(1, 6),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= projection.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    Dates.monthYear(projection[i].month).substring(0, 3),
                    style: t.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceTop,
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            getTooltipItems: (spots) => spots.map((s) {
              final p = projection[s.x.toInt()];
              final closing = p.closing.isEmpty
                  ? ''
                  : '\n${p.closing.join(", ")} closes';
              return LineTooltipItem(
                '${Dates.monthYear(p.month)}\n${Money.inr(p.amount)}$closing',
                t.bodySmall!.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (_, indices) => indices
              .map(
                (_) => TouchedSpotIndicatorData(
                  FlLine(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.accent,
                      strokeColor: AppColors.bg,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            color: AppColors.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) =>
                  closureIndices.contains(spot.x.toInt()),
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 5,
                color: AppColors.bg,
                strokeColor: AppColors.success,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.28),
                  AppColors.accent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureLegend extends StatelessWidget {
  const _ClosureLegend({required this.projection});
  final List<MonthOutflow> projection;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final closures = <MonthOutflow>[];
    for (final p in projection) {
      if (p.closing.isNotEmpty) closures.add(p);
    }
    if (closures.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 0.5, color: AppColors.border),
        const Gap(14),
        Row(
          children: [
            const Icon(LucideIcons.partyPopper,
                size: 14, color: AppColors.success),
            const Gap(6),
            Text(
              'Loans closing',
              style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in closures.take(5))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${c.closing.first} • ${Dates.monthYear(c.month).substring(0, 3)} ${c.month.year.toString().substring(2)}',
                  style: t.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickWinCard extends ConsumerWidget {
  const _QuickWinCard({required this.loan});
  final dynamic loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final accent = AppColors.loanAccent(loan.accentIndex);
    return GlowCard(
      glowColor: accent,
      glow: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.zap,
                  size: 16, color: AppColors.accent),
              const Gap(6),
              Text('CLOSING SOONEST',
                  style: t.labelSmall
                      ?.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const Gap(10),
          Text(loan.lender, style: t.headlineMedium),
          const Gap(6),
          Text(
            '${loan.emisRemaining} EMI${loan.emisRemaining == 1 ? '' : 's'} left • closes ${Dates.monthYear(loan.closureDate)}',
            style: t.bodyMedium,
          ),
          const Gap(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.surfaceTop),
                FractionallySizedBox(
                  widthFactor: loan.progress,
                  child: Container(
                    height: 8,
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
        ],
      ),
    );
  }
}

class _BigRow extends StatelessWidget {
  const _BigRow({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: t.bodyMedium)),
        Text(
          value,
          style: t.headlineMedium?.copyWith(
            color: color ?? AppColors.textPrimary,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}
