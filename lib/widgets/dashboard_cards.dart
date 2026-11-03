// lib/widgets/dashboard_cards.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/category.dart';
import '../models/monthly_summary.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'common.dart';

/// Big "Total investments this month" card.
class TotalSpentCard extends StatelessWidget {
  const TotalSpentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final s = context.s;
    final fmt = context.fmt;
    final summary = provider.currentMonth;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.hotPink.withValues(alpha: 0.14),
              AppColors.lilac.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.totalInvestments,
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      fmt.money(summary.total),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.hotPink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.count} ${s.transactions} • ${s.todaySpent}: ${fmt.money(provider.todayTotal)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('☕', style: TextStyle(fontSize: 26)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress towards the monthly budget goal.
class BudgetGoalCard extends StatelessWidget {
  const BudgetGoalCard({super.key, this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final budget = context.watch<SettingsProvider>().monthlyBudget;
    final s = context.s;
    final fmt = context.fmt;
    final spent = provider.currentMonth.total;
    final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget;
    final remaining = (budget - spent).clamp(0.0, double.infinity);

    return SectionCard(
      emoji: '🎀',
      title: s.monthlyGoal,
      trailing: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            fmt.money(budget, decimals: 0),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.hotPink),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.blush,
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? AppColors.danger : AppColors.hotPink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            over ? s.overBudget : s.leftForCoffee(fmt.money(remaining)),
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bars per category.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key, required this.summary, this.limit});

  final MonthlySummary summary;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final ar = context.watch<SettingsProvider>().isArabic;
    final total = summary.total;
    var entries = summary.byCategory.entries.toList();
    if (limit != null && entries.length > limit!) {
      entries = entries.take(limit!).toList();
    }

    return SectionCard(
      emoji: '✨',
      title: s.spendingBreakdown,
      child: entries.isEmpty
          ? Text(s.noDataMonth,
              style: TextStyle(color: Theme.of(context).hintColor))
          : Column(
              children: entries.map((entry) {
                final cat = ExpenseCategory.byId(entry.key);
                final pct = total > 0 ? entry.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${cat.emoji} ',
                              style: const TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(cat.label(ar),
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            '${fmt.money(entry.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor:
                              cat.color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// Little stat tile (label + big number).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}

/// One sentence insight with an emoji ("You spend most on Fridays").
class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.emoji, required this.text, this.color});

  final String emoji;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (color ?? AppColors.hotPink).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
