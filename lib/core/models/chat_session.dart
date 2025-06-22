import 'chat_message.dart';

class ChatSession {
  final String id;
  String nickname;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    this.nickname = 'New Chat',
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}
