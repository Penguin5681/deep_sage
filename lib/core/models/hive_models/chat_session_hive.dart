import 'package:hive_flutter/adapters.dart';
part 'chat_session_hive.g.dart';

@HiveType(typeId: 2)
class ChatSessionHive {
  @HiveField(0)
  String sessionId;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String model;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  ChatSessionHive({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
  });
}
