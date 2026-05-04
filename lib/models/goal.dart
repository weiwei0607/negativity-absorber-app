import 'package:hive/hive.dart';
import 'emotion_type.dart';

part 'goal.g.dart';

@HiveType(typeId: 2)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final EmotionType? targetEmotion;

  @HiveField(3)
  final int maxCount;

  @HiveField(4)
  final int periodDays;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isActive;

  Goal({
    required this.id,
    required this.title,
    this.targetEmotion,
    required this.maxCount,
    required this.periodDays,
    required this.createdAt,
    this.isActive = true,
  });

  DateTime get endDate => createdAt.add(Duration(days: periodDays));

  bool isExpired(DateTime now) => now.isAfter(endDate);

  Goal copyWith({bool? isActive}) {
    return Goal(
      id: id,
      title: title,
      targetEmotion: targetEmotion,
      maxCount: maxCount,
      periodDays: periodDays,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
