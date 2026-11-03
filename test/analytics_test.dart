// test/analytics_test.dart – monthly summaries and trends.
import 'package:girl_maths/models/expense.dart';
import 'package:girl_maths/models/monthly_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Expense e(String title, double amount, DateTime date, String cat) =>
    Expense(title: title, amount: amount, date: date, categoryId: cat);

void main() {
  final data = [
    e('Latte', 80, DateTime(2026, 11, 2), 'coffee'), // Monday
    e('Dress', 1200, DateTime(2026, 11, 6), 'fashion'), // Friday
    e('Cupcake', 50, DateTime(2026, 11, 6), 'treat'), // Friday
    e('Latte', 90, DateTime(2026, 11, 9), 'coffee'), // Monday
    e('Rent', 3000, DateTime(2026, 10, 1), 'bills'),
    e('Old', 500, DateTime(2025, 12, 31), 'other'),
  ];
  final nov = MonthlySummary(DateTime(2026, 11, 15), data);

  test('only expenses of the month are included', () {
    expect(nov.count, 4);
    expect(nov.total, 1420);
  });

  test('categories sorted by amount', () {
    expect(nov.byCategory.keys.toList(), ['fashion', 'coffee', 'treat']);
    expect(nov.byCategory['coffee'], 170);
    expect(nov.topCategoryId, 'fashion');
  });

  test('per-day and per-weekday buckets', () {
    expect(nov.byDay.length, 30);
    expect(nov.byDay[5], 1250); // 6 Nov
    expect(nov.busiestWeekday, DateTime.friday);
  });

  test('average and projection use elapsed days', () {
    final now = DateTime(2026, 11, 10);
    expect(nov.elapsedDays(now), 10);
    expect(nov.averagePerDay(now), 142);
    expect(nov.projectedTotal(now), closeTo(4260, 0.001));
    // past months are complete
    final oct = MonthlySummary(DateTime(2026, 10), data);
    expect(oct.elapsedDays(now), 31);
    expect(oct.projectedTotal(now), 3000);
  });

  test('biggest expense and basically-free count', () {
    expect(nov.biggestExpense!.title, 'Dress');
    expect(nov.basicallyFreeCount(100), 3);
  });

  test('monthly totals cross the year boundary', () {
    final totals = monthlyTotals(data, DateTime(2026, 1), 2);
    expect(totals.first.key, DateTime(2025, 12));
    expect(totals.first.value, 500);
    expect(totals.last.key, DateTime(2026, 1));
    expect(totals.last.value, 0);
  });

  test('percent change', () {
    expect(percentChange(0, 100), isNull);
    expect(percentChange(100, 150), 50);
    expect(percentChange(200, 100), -50);
  });

  test('empty month', () {
    final empty = MonthlySummary(DateTime(2030, 1), data);
    expect(empty.isEmpty, isTrue);
    expect(empty.topCategoryId, isNull);
    expect(empty.busiestWeekday, isNull);
    expect(empty.biggestExpense, isNull);
  });
}
