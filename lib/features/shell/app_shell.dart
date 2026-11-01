import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/loan_providers.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../loans/loans_screen.dart';
import '../planner/planner_screen.dart';
import 'widgets/freedom_nav_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    LoansScreen(),
    PlannerScreen(),
    InsightsScreen(),
  ];

  static const _tabs = [
    NavTab(icon: LucideIcons.house, label: 'Home'),
    NavTab(icon: LucideIcons.layers, label: 'Loans'),
    NavTab(icon: LucideIcons.calculator, label: 'Plan'),
    NavTab(icon: LucideIcons.chartLine, label: 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: FreedomNavBar(
        tabs: _tabs,
        index: _index,
        onChanged: (i) {
          setState(() => _index = i);
          ref.read(navIndexProvider.notifier).state = i;
          if (i == 0) {
            ref.read(homeVisitTickProvider.notifier).state++;
          } else if (i == 3) {
            ref.read(insightsVisitTickProvider.notifier).state++;
          }
        },
      ),
    );
  }
}
