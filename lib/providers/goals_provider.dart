// lib/providers/goals_provider.dart
import 'package:flutter/foundation.dart';

import '../models/savings_goal.dart';
import '../services/sync_repository.dart';

class GoalsProvider with ChangeNotifier {
  GoalsProvider(this._repo);

  final SyncRepository _repo;

  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;

  double get totalSaved => _goals.fold(0.0, (s, g) => s + g.savedAmount);
  double get totalTarget => _goals.fold(0.0, (s, g) => s + g.targetAmount);

  Future<void> init() async {
    _goals = await _repo.cachedGoals();
    _isLoading = false;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      _goals = await _repo.refreshGoals();
    } catch (e) {
      debugPrint('Goals sync failed, using cache: $e');
    }
    notifyListeners();
  }

  Future<void> saveGoal(SavingsGoal goal) async {
    _upsert(goal);
    notifyListeners();
    _upsert(await _repo.saveGoal(goal));
    notifyListeners();
  }

  Future<void> addMoney(SavingsGoal goal, double amount) => saveGoal(
        goal.copyWith(
            savedAmount: (goal.savedAmount + amount).clamp(0.0, double.infinity)),
      );

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    await _repo.deleteGoal(id);
  }

  void _upsert(SavingsGoal g) {
    final i = _goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      _goals[i] = g;
    } else {
      _goals.add(g);
    }
  }

  void clearLocal() {
    _goals = [];
    notifyListeners();
  }
}
