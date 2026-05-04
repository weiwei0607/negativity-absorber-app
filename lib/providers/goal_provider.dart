import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import '../models/chat_session.dart';

class GoalNotifier extends StateNotifier<List<Goal>> {
  Box<Goal>? _box;

  GoalNotifier() : super([]);

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GoalAdapter());
    }
    _box = await Hive.openBox<Goal>('goals');
    _refresh();
  }

  void _refresh() {
    if (_box == null) return;
    final now = DateTime.now();
    final all = _box!.values.toList();
    // Auto-deactivate expired goals
    for (final goal in all) {
      if (goal.isActive && goal.isExpired(now)) {
        final updated = goal.copyWith(isActive: false);
        _box!.put(goal.id, updated);
      }
    }
    state = _box!.values.toList().reversed.toList();
  }

  Future<void> addGoal(Goal goal) async {
    if (_box == null) return;
    await _box!.put(goal.id, goal);
    _refresh();
  }

  Future<void> deleteGoal(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
    _refresh();
  }

  Future<void> toggleGoal(String id) async {
    if (_box == null) return;
    final goal = _box!.get(id);
    if (goal != null) {
      final updated = goal.copyWith(isActive: !goal.isActive);
      await _box!.put(id, updated);
      _refresh();
    }
  }

  double getProgress(Goal goal, List<ChatSession> sessions) {
    final now = DateTime.now();
    final relevant = sessions.where((s) {
      final d = s.startedAt;
      return d.isAfter(goal.createdAt) &&
          d.isBefore(goal.endDate) &&
          (goal.targetEmotion == null || s.taggedEmotion == goal.targetEmotion);
    }).toList();

    if (goal.maxCount == 0) return 1.0;
    final ratio = relevant.length / goal.maxCount;
    return ratio.clamp(0.0, 1.0);
  }

  bool isGoalAchieved(Goal goal, List<ChatSession> sessions) {
    return getProgress(goal, sessions) < 1.0;
  }

  int getCurrentCount(Goal goal, List<ChatSession> sessions) {
    return sessions.where((s) {
      final d = s.startedAt;
      return d.isAfter(goal.createdAt) &&
          d.isBefore(goal.endDate) &&
          (goal.targetEmotion == null || s.taggedEmotion == goal.targetEmotion);
    }).length;
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, List<Goal>>(
  (ref) => GoalNotifier(),
);
