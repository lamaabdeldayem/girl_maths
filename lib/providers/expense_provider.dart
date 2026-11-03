// lib/providers/expense_provider.dart
//
// Central expense state (Lecture 6 – Providers). Screens listen with
// context.watch / Consumer and call the methods below; persistence and the
// Firebase sync are delegated to SyncRepository.
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/monthly_summary.dart';
import '../services/sync_repository.dart';

class ExpenseProvider with ChangeNotifier {
  ExpenseProvider(this._repo, {this.onSynced});

  final SyncRepository _repo;

  /// Called after a successful sync with Firebase (used to store the time).
  final void Function(DateTime when)? onSynced;

  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _syncError;
  int _pendingCount = 0;

  // UI state shared between screens (kept here so it survives rotation and
  // switching between bottom-bar and rail layouts).
  DateTime _selectedMonth = monthStart(DateTime.now());
  String _query = '';
  String? _categoryFilter;
  String? _selectedExpenseId; // master/detail on wide screens

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  int get pendingCount => _pendingCount;
  bool get hasBackend => _repo.hasBackend;
  DateTime get selectedMonth => _selectedMonth;
  String get query => _query;
  String? get categoryFilter => _categoryFilter;
  String? get selectedExpenseId => _selectedExpenseId;

  Expense? byId(String? id) {
    if (id == null) return null;
    for (final e in _expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Loading & syncing (cache first, then network)
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    _expenses = await _repo.cachedExpenses();
    _isLoading = false;
    await _updatePending();
    notifyListeners();
    await refresh();
  }

  /// Pull-to-refresh / "Sync now".
  Future<void> refresh() async {
    if (!_repo.hasBackend) {
      _expenses = await _repo.cachedExpenses();
      notifyListeners();
      return;
    }
    _isSyncing = true;
    notifyListeners();
    try {
      _expenses = await _repo.refreshExpenses();
      _syncError = null;
      onSynced?.call(DateTime.now());
    } catch (e) {
      _syncError = e.toString();
      debugPrint('Sync failed, using cache: $e');
    } finally {
      _isSyncing = false;
      await _updatePending();
      notifyListeners();
    }
  }

  Future<void> _updatePending() async {
    _pendingCount = await _repo.pendingCount();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------
  Future<void> addExpense(Expense expense) => _save(expense);

  Future<void> updateExpense(Expense expense) => _save(expense);

  Future<void> _save(Expense expense) async {
    // optimistic update so the UI reacts instantly
    _upsertLocal(expense);
    notifyListeners();
    final stored = await _repo.saveExpense(expense);
    _upsertLocal(stored);
    await _updatePending();
    notifyListeners();
  }

  void _upsertLocal(Expense e) {
    final i = _expenses.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      _expenses[i] = e;
    } else {
      _expenses.add(e);
    }
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Removes the expense and returns it so the UI can offer "Undo".
  Future<Expense?> removeExpense(String id) async {
    final removed = byId(id);
    if (removed == null) return null;
    _expenses.removeWhere((e) => e.id == id);
    if (_selectedExpenseId == id) _selectedExpenseId = null;
    notifyListeners();
    await _repo.deleteExpense(id);
    await _updatePending();
    notifyListeners();
    return removed;
  }

  Future<void> restoreExpense(Expense expense) => _save(expense);

  // ---------------------------------------------------------------------------
  // Filters / selection
  // ---------------------------------------------------------------------------
  void setMonth(DateTime month) {
    _selectedMonth = monthStart(month);
    notifyListeners();
  }

  void previousMonth() =>
      setMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(monthStart(DateTime.now()))) setMonth(next);
  }

  bool get canGoNext =>
      _selectedMonth.isBefore(monthStart(DateTime.now()));

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setCategoryFilter(String? id) {
    _categoryFilter = id;
    notifyListeners();
  }

  void selectExpense(String? id) {
    _selectedExpenseId = id;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------------
  MonthlySummary summaryFor(DateTime month) => MonthlySummary(month, _expenses);

  MonthlySummary get currentMonth => summaryFor(DateTime.now());
  MonthlySummary get selectedSummary => summaryFor(_selectedMonth);

  double get todayTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// Expenses of the selected month after search + category filter.
  List<Expense> get filteredExpenses {
    final q = _query.trim().toLowerCase();
    return selectedSummary.expenses.where((e) {
      if (_categoryFilter != null && e.categoryId != _categoryFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          (e.note ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<Expense> recent([int count = 5]) => _expenses.take(count).toList();

  List<MapEntry<DateTime, double>> lastMonths(int count) =>
      monthlyTotals(_expenses, _selectedMonth, count);

  Future<void> clearLocal() async {
    await _repo.local.clearAll();
    _expenses = [];
    _selectedExpenseId = null;
    await _updatePending();
    notifyListeners();
  }
}
