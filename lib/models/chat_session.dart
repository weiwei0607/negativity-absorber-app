import 'package:hive/hive.dart';
import 'chat_message.dart';
import 'emotion_type.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 4)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startedAt;

  @HiveField(2)
  final DateTime? endedAt;

  @HiveField(3)
  final List<ChatMessage> messages;

  @HiveField(4)
  final EmotionType? taggedEmotion;

  ChatSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.messages,
    this.taggedEmotion,
  });
}
