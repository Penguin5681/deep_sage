import 'package:hive_flutter/adapters.dart';
part 'chat_message_hive.g.dart';

@HiveType(typeId: 3)
class ChatMessageHive {
  @HiveField(0)
  String messageId;

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  String role;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  ChatMessageHive({
    required this.messageId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });
}
