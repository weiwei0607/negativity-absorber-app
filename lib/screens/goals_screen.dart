import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/emotion_type.dart';
import '../providers/goal_provider.dart';
import '../providers/session_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    final sessions = ref.watch(sessionProvider);
    final goalNotifier = ref.read(goalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 情緒目標'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context, ref),
          ),
        ],
      ),
      body: goals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.track_changes_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('還沒有設定目標', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('設定一個小目標，例如「本週生氣不超過 3 次」', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goalNotifier.getProgress(goal, sessions);
                final current = goalNotifier.getCurrentCount(goal, sessions);
                final isAchieved = current < goal.maxCount;
                final isExpired = goal.isExpired(DateTime.now());

                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => goalNotifier.deleteGoal(goal.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isAchieved && !isExpired)
                                const Chip(
                                  label: Text('達成 🎉', style: TextStyle(fontSize: 11)),
                                  backgroundColor: Color(0xFF00B894),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (isExpired)
                                const Chip(
                                  label: Text('已結束', style: TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.grey,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goal.targetEmotion?.emoji ?? "🌀"} ${goal.targetEmotion?.label ?? "全部情緒"}  ·  ${DateFormat('MM/dd').format(goal.createdAt)} ~ ${DateFormat('MM/dd').format(goal.endDate)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      isAchieved ? const Color(0xFF00B894) : const Color(0xFFE94560),
                                    ),
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$current / ${goal.maxCount}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isExpired
                                ? '目標期間已結束'
                                : isAchieved
                                    ? '太棒了！你控制在目標範圍內 👏'
                                    : '已達到目標上限，注意情緒照顧',
                            style: TextStyle(
                              fontSize: 12,
                              color: isAchieved ? const Color(0xFF00B894) : const Color(0xFFE94560),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final selectedEmotion = ValueNotifier<EmotionType?>(null);
    final maxCountController = TextEditingController(text: '3');
    final daysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增情緒目標'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('我想要控制...', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              ValueListenableBuilder<EmotionType?>(
                valueListenable: selectedEmotion,
                builder: (context, emotion, _) {
                  return Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('全部情緒'),
                        selected: emotion == null,
                        onSelected: (_) => selectedEmotion.value = null,
                      ),
                      ...EmotionType.values.map((e) => ChoiceChip(
                            label: Text('${e.emoji} ${e.label}'),
                            selected: emotion == e,
                            onSelected: (_) => selectedEmotion.value = e,
                          )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '次數上限',
                  hintText: '例如：3',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '目標天數',
                  hintText: '例如：7',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final maxCount = int.tryParse(maxCountController.text) ?? 3;
              final days = int.tryParse(daysController.text) ?? 7;
              final emotion = selectedEmotion.value;
              final title = emotion != null
                  ? '每 ${days}天 ${emotion.label} 不超過 ${maxCount} 次'
                  : '每 ${days}天 負面情緒 不超過 ${maxCount} 次';

              final goal = Goal(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                targetEmotion: emotion,
                maxCount: maxCount,
                periodDays: days,
                createdAt: DateTime.now(),
              );

              ref.read(goalProvider.notifier).addGoal(goal);
              Navigator.pop(context);
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }
}
