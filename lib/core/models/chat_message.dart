class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isTyping;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.isTyping = false,
    this.isError = false,
  });
}
