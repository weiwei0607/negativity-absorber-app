import 'package:hive/hive.dart';

part 'emotion_type.g.dart';

@HiveType(typeId: 1)
enum EmotionType {
  @HiveField(0)
  angry('生氣', '😡', 0xFFE94560),
  @HiveField(1)
  sad('難過', '😢', 0xFF5F72BE),
  @HiveField(2)
  tired('疲憊', '😫', 0xFF9B59B6),
  @HiveField(3)
  anxious('焦慮', '😰', 0xFFF39C12),
  @HiveField(4)
  frustrated('沮喪', '😤', 0xFFE67E22),
  @HiveField(5)
  mixed('複雜', '🌀', 0xFF95A5A6);

  final String label;
  final String emoji;
  final int colorValue;

  const EmotionType(this.label, this.emoji, this.colorValue);
}
