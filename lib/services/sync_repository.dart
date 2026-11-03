// lib/services/sync_repository.dart
//
// Offline-first repository = Lecture 6 caching flow:
//
//   Startup -> load from local cache -> show immediately
//           -> fetch from Firebase -> update provider -> save to cache
//
// Every write goes to the cache first (so the UI never waits for the network)
// and is then pushed to Firebase. If that fails (no internet) the row stays
// `is_synced = 0` / in `pending_deletes` and is pushed on the next refresh.
import '../models/expense.dart';
import '../models/savings_goal.dart';
import 'firebase_service.dart';
import 'local_store.dart';

class SyncRepository {
  SyncRepository({required this.local, this.remote});

  final LocalStore local;
  final FirebaseService? remote;

  static const expensesPath = 'expenses';
  static const goalsPath = 'goals';

  bool get hasBackend => remote?.isConfigured ?? false;

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------
  Future<List<Expense>> cachedExpenses() => local.fetchExpenses();

  /// Pushes pending changes, then pulls the server copy into the cache.
  /// Throws if the server cannot be reached (caller keeps showing the cache).
  Future<List<Expense>> refreshExpenses() async {
    if (!hasBackend) return local.fetchExpenses();
    await pushPending();
    final server = await remote!.fetchCollection(expensesPath);
    final cached = await local.fetchExpenses();
    final images = {
      for (final e in cached)
        if (e.imagePath != null) e.id: e.imagePath,
    };
    final list = server.entries
        .map((en) =>
            Expense.fromJson(en.key, en.value, localImagePath: images[en.key]))
        .toList();
    await local.replaceSyncedExpenses(list);
    return local.fetchExpenses();
  }

  /// Insert or update. Returns the stored version (with its sync flag).
  Future<Expense> saveExpense(Expense expense) async {
    var item = expense.copyWith(isSynced: false, updatedAt: DateTime.now());
    await local.upsertExpense(item);
    if (hasBackend) {
      try {
        await remote!.put(expensesPath, item.id, item.toJson());
        item = item.copyWith(isSynced: true);
        await local.upsertExpense(item);
      } catch (_) {
        // offline: stays unsynced, pushed later by pushPending()
      }
    }
    return item;
  }

  Future<void> deleteExpense(String id) async {
    await local.deleteExpense(id);
    await _deleteRemote(expensesPath, id);
  }

  // ---------------------------------------------------------------------------
  // Savings goals
  // ---------------------------------------------------------------------------
  Future<List<SavingsGoal>> cachedGoals() => local.fetchGoals();

  Future<List<SavingsGoal>> refreshGoals() async {
    if (!hasBackend) return local.fetchGoals();
    await pushPending();
    final server = await remote!.fetchCollection(goalsPath);
    final cached = await local.fetchGoals();
    final images = {
      for (final g in cached)
        if (g.imagePath != null) g.id: g.imagePath,
    };
    final list = server.entries
        .map((en) => SavingsGoal.fromJson(en.key, en.value,
            localImagePath: images[en.key]))
        .toList();
    await local.replaceSyncedGoals(list);
    return local.fetchGoals();
  }

  Future<SavingsGoal> saveGoal(SavingsGoal goal) async {
    var item = goal.copyWith(isSynced: false);
    await local.upsertGoal(item);
    if (hasBackend) {
      try {
        await remote!.put(goalsPath, item.id, item.toJson());
        item = item.copyWith(isSynced: true);
        await local.upsertGoal(item);
      } catch (_) {}
    }
    return item;
  }

  Future<void> deleteGoal(String id) async {
    await local.deleteGoal(id);
    await _deleteRemote(goalsPath, id);
  }

  // ---------------------------------------------------------------------------
  // Sync helpers
  // ---------------------------------------------------------------------------
  Future<void> _deleteRemote(String collection, String id) async {
    if (remote == null) return;
    if (!hasBackend) {
      await local.addPendingDelete(id, collection);
      return;
    }
    try {
      await remote!.delete(collection, id);
    } catch (_) {
      await local.addPendingDelete(id, collection);
    }
  }

  /// Pushes everything that was changed while offline.
  Future<void> pushPending() async {
    if (!hasBackend) return;
    for (final entry in await local.fetchPendingDeletes()) {
      await remote!.delete(entry.value, entry.key);
      await local.removePendingDelete(entry.key);
    }
    for (final e in await local.fetchExpenses()) {
      if (!e.isSynced) {
        await remote!.put(expensesPath, e.id, e.toJson());
        await local.upsertExpense(e.copyWith(isSynced: true));
      }
    }
    for (final g in await local.fetchGoals()) {
      if (!g.isSynced) {
        await remote!.put(goalsPath, g.id, g.toJson());
        await local.upsertGoal(g.copyWith(isSynced: true));
      }
    }
  }

  Future<int> pendingCount() async {
    final deletes = await local.fetchPendingDeletes();
    final expenses = await local.fetchExpenses();
    final goals = await local.fetchGoals();
    return deletes.length +
        expenses.where((e) => !e.isSynced).length +
        goals.where((g) => !g.isSynced).length;
  }
}
