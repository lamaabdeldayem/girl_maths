// test/models_test.dart – Phase 2 unit tests for the data models.
import 'package:girl_maths/models/category.dart';
import 'package:girl_maths/models/expense.dart';
import 'package:girl_maths/models/savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense', () {
    final expense = Expense(
      id: 'e1',
      title: 'Iced Coffee',
      amount: 150.0,
      date: DateTime(2026, 9, 29),
      categoryId: 'coffee',
      note: 'with oat milk',
      imagePath: '/tmp/receipt.jpg',
    );

    test('converts to a SQLite map', () {
      final map = expense.toMap();
      expect(map['id'], 'e1');
      expect(map['title'], 'Iced Coffee');
      expect(map['amount'], 150.0);
      expect(map['category_id'], 'coffee');
      expect(map['date'], '2026-09-29T00:00:00.000');
      expect(map['is_synced'], 0);
    });

    test('SQLite map round-trip keeps every field', () {
      final copy = Expense.fromMap(expense.toMap());
      expect(copy, expense);
      expect(copy.note, 'with oat milk');
      expect(copy.imagePath, '/tmp/receipt.jpg');
    });

    test('Firebase JSON does not upload the local image path', () {
      final json = expense.toJson();
      expect(json.containsKey('imagePath'), isFalse);
      final back = Expense.fromJson('e1', json, localImagePath: '/x.jpg');
      expect(back.title, expense.title);
      expect(back.amount, expense.amount);
      expect(back.isSynced, isTrue);
      expect(back.imagePath, '/x.jpg');
    });

    test('reads rows written by the first version of the app', () {
      final legacy = Expense.fromMap({
        'id': 7,
        'title': 'Nails',
        'amount': 300,
        'date': '2026-10-01T10:00:00.000',
        'category': 'Self Care & Nails 💅',
      });
      expect(legacy.id, '7');
      expect(legacy.amount, 300.0);
      expect(legacy.categoryId, 'selfcare');
    });

    test('generated ids are unique and valid Firebase keys', () {
      final ids = List.generate(500, (_) => Expense.generateId()).toSet();
      expect(ids.length, 500);
      for (final id in ids) {
        expect(RegExp(r'[.#$\[\]/]').hasMatch(id), isFalse);
      }
    });
  });

  group('ExpenseCategory', () {
    test('legacy labels map to new ids', () {
      expect(ExpenseCategory.migrateLegacy('Iced Coffee ☕'), 'coffee');
      expect(ExpenseCategory.migrateLegacy('Cost Per Wear 👗'), 'fashion');
      expect(ExpenseCategory.migrateLegacy('Bills (Ugh) 💸'), 'bills');
      expect(ExpenseCategory.migrateLegacy('something else'), 'other');
    });

    test('unknown id falls back to "other"', () {
      expect(ExpenseCategory.byId('nope').id, 'other');
    });
  });

  group('SavingsGoal', () {
    test('progress and remaining', () {
      final g = SavingsGoal(title: 'Bag', targetAmount: 1000, savedAmount: 250);
      expect(g.progress, 0.25);
      expect(g.remaining, 750);
      expect(g.isCompleted, isFalse);
    });

    test('daily amount needed to reach the deadline', () {
      final g = SavingsGoal(
        title: 'Trip',
        targetAmount: 1000,
        savedAmount: 400,
        deadline: DateTime(2026, 11, 11),
      );
      // 600 left over 10 days
      expect(g.dailyNeeded(DateTime(2026, 11, 1, 15)), 60);
    });

    test('map round-trip', () {
      final g = SavingsGoal(
          title: 'Bag', emoji: '👜', targetAmount: 1000, deadline: DateTime(2027));
      final back = SavingsGoal.fromMap(g.toMap());
      expect(back.id, g.id);
      expect(back.title, 'Bag');
      expect(back.deadline, DateTime(2027));
    });
  });
}
