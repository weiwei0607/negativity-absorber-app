import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 3)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final String content;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.isUser,
    required this.content,
  });
}
