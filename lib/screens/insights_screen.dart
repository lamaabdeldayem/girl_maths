// lib/screens/insights_screen.dart
//
// Monthly summaries, graphs and discovered trends (Phase 3).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../models/category.dart';
import '../models/monthly_summary.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<ExpenseProvider>();
    final ar = settings.isArabic;
    final month = provider.selectedSummary;
    final prevMonth = provider.summaryFor(
        DateTime(month.month.year, month.month.month - 1));
    final now = DateTime.now();
    final history = provider.lastMonths(6);
    final hasHistory = history.any((e) => e.value > 0);

    // ------------------------------------------------------------- summary
    final stats = Row(
      children: [
        Expanded(
          child: StatTile(
              emoji: '💸', label: s.navExpenses, value: fmt.moneyShort(month.total)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
              emoji: '📅',
              label: s.perDay,
              value: fmt.moneyShort(month.averagePerDay(now))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
              emoji: '🧾', label: s.transactions, value: '${month.count}'),
        ),
      ],
    );

    // -------------------------------------------------------------- trends
    final insights = <Widget>[];
    final change = percentChange(prevMonth.total, month.total);
    if (change == null) {
      insights.add(InsightTile(emoji: '🗓️', text: s.noLastMonth));
    } else {
      insights.add(InsightTile(
        emoji: change > 0 ? '📈' : '📉',
        color: change > 0 ? AppColors.danger : AppColors.success,
        text: s.vsLastMonth(fmt.percent(change), change > 0),
      ));
    }
    final top = month.topCategoryId;
    if (top != null) {
      final c = ExpenseCategory.byId(top);
      insights.add(InsightTile(
          emoji: c.emoji, color: c.color, text: s.topCategory(c.label(ar))));
    }
    final busiest = month.busiestWeekday;
    if (busiest != null) {
      insights.add(InsightTile(
          emoji: '📆', text: s.busiestDay(s.weekdays[busiest - 1])));
    }
    final biggest = month.biggestExpense;
    if (biggest != null) {
      insights.add(InsightTile(
          emoji: '💎', text: s.biggest(biggest.title, fmt.money(biggest.amount))));
    }
    if (sameMonth(month.month, now) && !month.isEmpty) {
      final projected = month.projectedTotal(now);
      final diff = projected - settings.monthlyBudget;
      insights.add(InsightTile(
        emoji: '🔮',
        color: diff > 0 ? AppColors.danger : AppColors.success,
        text: diff > 0
            ? s.projectionOver(fmt.money(diff))
            : s.projectionUnder(fmt.money(-diff)),
      ));
    }
    final free = month.basicallyFreeCount(settings.freeThreshold);
    if (free > 0) {
      insights.add(InsightTile(emoji: '🆓', text: s.basicallyFree(free)));
    }

    // -------------------------------------------------------------- charts
    final days = daysInMonth(month.month);
    final todayIndex = sameMonth(month.month, now) ? now.day - 1 : null;
    final weekdayValues = month.byWeekday;

    final cards = <Widget>[
      SectionCard(
        emoji: '✨',
        title: s.trends,
        child: Column(children: insights),
      ),
      if (!month.isEmpty)
        SectionCard(
          emoji: '🍩',
          title: s.byCategory,
          child: CategoryPieChart(data: month.byCategory),
        ),
      if (!month.isEmpty)
        SectionCard(
          emoji: '📊',
          title: s.dailySpending,
          child: SpendingBarChart(
            values: month.byDay,
            labelFor: (i) => '${i + 1}',
            labelEvery: days > 20 ? 5 : 1,
            highlightIndex: todayIndex,
          ),
        ),
      if (!month.isEmpty)
        SectionCard(
          emoji: '🗓️',
          title: s.byWeekday,
          child: SpendingBarChart(
            values: weekdayValues,
            labelFor: (i) => s.weekdaysShort[i],
            highlightIndex: busiest == null ? null : busiest - 1,
          ),
        ),
      if (hasHistory)
        SectionCard(
          emoji: '📈',
          title: s.last6Months,
          child: MonthlyTrendChart(
            points: history,
            budget: settings.monthlyBudget,
          ),
        ),
      if (!month.isEmpty) CategoryBreakdownCard(summary: month),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.insights)),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Center(child: MonthSelector(label: fmt.month(month.month))),
            const SizedBox(height: 8),
            if (month.isEmpty)
              EmptyState(message: s.noDataMonth)
            else ...[
              stats,
              const SizedBox(height: 12),
            ],
            // 1 column on phones, 2 in landscape/tablets, 3 on desktops
            ResponsiveColumns(
              minItemWidth: 360,
              maxColumns: 3,
              children: cards,
            ),
          ],
        ),
      ),
    );
  }
}
