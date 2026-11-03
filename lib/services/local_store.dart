// lib/services/local_store.dart
//
// Interface of the local cache. DatabaseHelper (SQLite) implements it in the
// app; tests use the in-memory implementation below.
import '../models/expense.dart';
import '../models/savings_goal.dart';

abstract class LocalStore {
  Future<List<Expense>> fetchExpenses();
  Future<void> upsertExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> replaceSyncedExpenses(List<Expense> fromServer);

  Future<List<SavingsGoal>> fetchGoals();
  Future<void> upsertGoal(SavingsGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> replaceSyncedGoals(List<SavingsGoal> fromServer);

  Future<void> addPendingDelete(String id, String collection);
  Future<List<MapEntry<String, String>>> fetchPendingDeletes();
  Future<void> removePendingDelete(String id);

  Future<void> clearAll();
}

/// Simple in-memory store (used by unit & widget tests).
class InMemoryLocalStore implements LocalStore {
  final Map<String, Expense> _expenses = {};
  final Map<String, SavingsGoal> _goals = {};
  final Map<String, String> _pendingDeletes = {};

  @override
  Future<List<Expense>> fetchExpenses() async =>
      _expenses.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<void> upsertExpense(Expense expense) async {
    _expenses[expense.id] = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
  }

  @override
  Future<void> replaceSyncedExpenses(List<Expense> fromServer) async {
    _expenses.removeWhere((_, e) => e.isSynced);
    for (final e in fromServer) {
      _expenses.putIfAbsent(e.id, () => e);
    }
  }

  @override
  Future<List<SavingsGoal>> fetchGoals() async => _goals.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> upsertGoal(SavingsGoal goal) async {
    _goals[goal.id] = goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.remove(id);
  }

  @override
  Future<void> replaceSyncedGoals(List<SavingsGoal> fromServer) async {
    _goals.removeWhere((_, g) => g.isSynced);
    for (final g in fromServer) {
      _goals.putIfAbsent(g.id, () => g);
    }
  }

  @override
  Future<void> addPendingDelete(String id, String collection) async {
    _pendingDeletes[id] = collection;
  }

  @override
  Future<List<MapEntry<String, String>>> fetchPendingDeletes() async =>
      _pendingDeletes.entries.toList();

  @override
  Future<void> removePendingDelete(String id) async {
    _pendingDeletes.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _expenses.clear();
    _goals.clear();
    _pendingDeletes.clear();
  }
}
