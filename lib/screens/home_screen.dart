// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_tile.dart';
import 'expense_detail_screen.dart';
import 'goals_screen.dart';
import 'main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.appName.toUpperCase()} 🎀'),
        actions: [
          const SyncStatusChip(),
          IconButton(
            tooltip: s.addExpense,
            icon: const Icon(Icons.add_circle, size: 30),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => showExpenseForm(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home',
        onPressed: () => showExpenseForm(context),
        icon: const Icon(Icons.add),
        label: Text(s.addExpense),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Wide (landscape / tablet): dashboard and list side by side.
                if (constraints.maxWidth >= 720) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: RefreshIndicator(
                          onRefresh: provider.refresh,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
                            children: const [_DashboardColumn()],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 96),
                          children: const [_RecentList(count: 12)],
                        ),
                      ),
                    ],
                  );
                }
                // Phone portrait: everything in one scrolling column.
                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: const [
                      _DashboardColumn(),
                      SizedBox(height: 8),
                      _RecentList(count: 5),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _DashboardColumn extends StatelessWidget {
  const _DashboardColumn();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<ExpenseProvider>();
    final month = provider.currentMonth;
    final now = DateTime.now();
    final free = month.basicallyFreeCount(settings.freeThreshold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Greeting + profile picture
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    MainNavigation.goTo(context, MainNavigation.settings),
                child: const ProfileAvatar(radius: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.greeting(settings.userName),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(fmt.day(now),
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const TotalSpentCard(),
        const SizedBox(height: 12),
        BudgetGoalCard(onEdit: () => editBudget(context)),
        const SizedBox(height: 12),
        // Quick stats: 3 tiles in a row (they shrink to fit any width)
        Row(
          children: [
            Expanded(
              child: StatTile(
                emoji: '📅',
                label: s.perDay,
                value: fmt.moneyShort(month.averagePerDay(now)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                emoji: '🔮',
                label: s.projected,
                value: fmt.moneyShort(month.projectedTotal(now)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                emoji: '🆓',
                label: s.freeLabel,
                value: '$free',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CategoryBreakdownCard(summary: month, limit: 4),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final provider = context.watch<ExpenseProvider>();
    final recent = provider.recent(count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.recentJustifications,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () =>
                    MainNavigation.goTo(context, MainNavigation.expenses),
                child: Text(s.seeAll),
              ),
            ],
          ),
        ),
        if (recent.isEmpty)
          EmptyState(message: s.noExpenses)
        else
          for (final e in recent)
            Padding(
              key: ValueKey(e.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: DismissibleExpense(
                expense: e,
                child: ExpenseTile(
                  expense: e,
                  onTap: () => openExpense(context, e, fromHome: true),
                ),
              ),
            ),
      ],
    );
  }
}
