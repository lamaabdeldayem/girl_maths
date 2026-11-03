// lib/models/monthly_summary.dart
//
// Pure (UI-free) analytics used by the Home and Insights screens.
// Kept free of Flutter imports so it can be unit-tested easily.
import 'expense.dart';

DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;
bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

class MonthlySummary {
  final DateTime month; // first day of the month
  final List<Expense> expenses;

  MonthlySummary(DateTime month, Iterable<Expense> all)
      : month = monthStart(month),
        expenses = all.where((e) => sameMonth(e.date, month)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

  double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);
  int get count => expenses.length;
  bool get isEmpty => expenses.isEmpty;

  /// Spending per category, largest first.
  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Index 0 = day 1 of the month.
  List<double> get byDay {
    final list = List<double>.filled(daysInMonth(month), 0);
    for (final e in expenses) {
      list[e.date.day - 1] += e.amount;
    }
    return list;
  }

  /// Index 0 = Monday ... 6 = Sunday.
  List<double> get byWeekday {
    final list = List<double>.filled(7, 0);
    for (final e in expenses) {
      list[e.date.weekday - 1] += e.amount;
    }
    return list;
  }

  /// Days that have passed in this month (whole month if it is in the past).
  int elapsedDays(DateTime now) {
    if (sameMonth(now, month)) return now.day;
    if (month.isAfter(now)) return 0;
    return daysInMonth(month);
  }

  double averagePerDay(DateTime now) {
    final days = elapsedDays(now);
    return days == 0 ? 0 : total / days;
  }

  /// Linear projection of the month-end total from the current pace.
  double projectedTotal(DateTime now) {
    if (!sameMonth(now, month)) return total;
    return averagePerDay(now) * daysInMonth(month);
  }

  String? get topCategoryId => byCategory.isEmpty ? null : byCategory.keys.first;

  Expense? get biggestExpense => expenses.isEmpty
      ? null
      : expenses.reduce((a, b) => a.amount >= b.amount ? a : b);

  /// 1 = Monday ... 7 = Sunday, null if no data.
  int? get busiestWeekday {
    if (expenses.isEmpty) return null;
    final w = byWeekday;
    var best = 0;
    for (var i = 1; i < 7; i++) {
      if (w[i] > w[best]) best = i;
    }
    return best + 1;
  }

  /// Number of purchases that girl math says were "basically free"
  /// (under the given threshold).
  int basicallyFreeCount(double threshold) =>
      expenses.where((e) => e.amount < threshold).length;
}

/// Totals for the last [count] months ending at [endMonth] (oldest first).
List<MapEntry<DateTime, double>> monthlyTotals(
    Iterable<Expense> all, DateTime endMonth, int count) {
  final end = monthStart(endMonth);
  return List.generate(count, (i) {
    final m = DateTime(end.year, end.month - (count - 1 - i));
    final total = all
        .where((e) => sameMonth(e.date, m))
        .fold(0.0, (s, e) => s + e.amount);
    return MapEntry(m, total);
  });
}

/// Percentage change between two values; null when there is no baseline.
double? percentChange(double previous, double current) {
  if (previous == 0) return null;
  return (current - previous) / previous * 100;
}
