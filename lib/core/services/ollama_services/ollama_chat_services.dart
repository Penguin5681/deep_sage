import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/adapters.dart';

import '../../models/hive_models/chat_message_hive.dart';
import '../../models/hive_models/chat_session_hive.dart';

class OllamaChatService {
  final String _baseUrl = dotenv.env['DEV_BASE_URL']!;

  final Box<ChatSessionHive> _sessionBox = Hive.box<ChatSessionHive>(
    'chat_sessions',
  );
  final Box<ChatMessageHive> _messageBox = Hive.box<ChatMessageHive>(
    'chat_messages',
  );

  Future<ChatSessionHive> createSession(
    String userId, {
    String title = 'New Chat',
    String model = 'mistral',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'title': title, 'model': model}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.body}');
    }
    final data = json.decode(response.body);
    final session = ChatSessionHive(
      sessionId: data['session_id'],
      userId: userId,
      title: data['title'],
      model: data['model'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['created_at']),
    );
    await _sessionBox.put(session.sessionId, session);
    return session;
  }

  Future<List<ChatSessionHive>> listSessions(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions?user_id=$userId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to list sessions: ${response.body}');
    }
    final list = json.decode(response.body) as List;
    final sessions =
        list.map((e) {
          return ChatSessionHive(
            sessionId: e['session_id'],
            userId: userId,
            title: e['title'],
            model: e['model'],
            createdAt: DateTime.parse(e['created_at']),
            updatedAt: DateTime.parse(e['updated_at']),
          );
        }).toList();

    await _sessionBox.clear();
    for (final s in sessions) {
      await _sessionBox.put(s.sessionId, s);
    }
    return sessions;
  }

  Future<List<ChatMessageHive>> getChatMessages(
    String sessionId,
    String userId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/chat/sessions/$sessionId/messages?user_id=$userId',
    );
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
    final list = json.decode(response.body) as List;
    final messages =
        list.map((e) {
          return ChatMessageHive(
            messageId: e['message_id'],
            sessionId: sessionId,
            role: e['role'],
            content: e['content'],
            createdAt: DateTime.parse(e['created_at']),
          );
        }).toList();

    for (final m in messages) {
      await _messageBox.put(m.messageId, m);
    }
    return messages;
  }

  Future<String> sendMessage(
    String sessionId,
    String userId,
    String message,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions/$sessionId/messages');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'message': message}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
    final data = json.decode(response.body);

    final userMsg = ChatMessageHive(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    await _messageBox.put(userMsg.messageId, userMsg);

    final botMsg = ChatMessageHive(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      role: 'assistant',
      content: data['response'],
      createdAt: DateTime.parse(data['created_at']),
    );
    await _messageBox.put(botMsg.messageId, botMsg);

    final old = _sessionBox.get(sessionId);
    if (old != null) {
      final updated = ChatSessionHive(
        sessionId: old.sessionId,
        userId: old.userId,
        title: old.title,
        model: old.model,
        createdAt: old.createdAt,
        updatedAt: DateTime.parse(data['created_at']),
      );
      await _sessionBox.put(sessionId, updated);
    }

    return data['response'];
  }

  // Update the sendMessage method in lib/core/services/ollama_services/ollama_chat_services.dart
  Future<Stream<String>> sendMessageStream(
    String sessionId,
    String userId,
    String message,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions/$sessionId/messages');

    // Save user message to Hive
    final userMsg = ChatMessageHive(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    await _messageBox.put(userMsg.messageId, userMsg);

    // Create StreamController to manage response chunks
    final controller = StreamController<String>();

    // Connect to SSE endpoint
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = json.encode({
      'user_id': userId,
      'message': message,
      'stream': true,
    });

    try {
      final response = await http.Client().send(request);

      // Handle stream response
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                try {
                  final jsonData = json.decode(data);

                  if (jsonData['type'] == 'chunk') {
                    controller.add(jsonData['content']);
                  } else if (jsonData['type'] == 'end') {
                    // Save the complete assistant message to Hive when stream ends
                    final botMsg = ChatMessageHive(
                      messageId:
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      sessionId: sessionId,
                      role: 'assistant',
                      content: jsonData['content'],
                      createdAt: DateTime.now(),
                    );
                    _messageBox.put(botMsg.messageId, botMsg);

                    // Update session timestamp
                    final old = _sessionBox.get(sessionId);
                    if (old != null) {
                      final updated = ChatSessionHive(
                        sessionId: old.sessionId,
                        userId: old.userId,
                        title: old.title,
                        model: old.model,
                        createdAt: old.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      _sessionBox.put(sessionId, updated);
                    }

                    controller.close();
                  } else if (jsonData['type'] == 'error') {
                    controller.addError(Exception(jsonData['message']));
                    controller.close();
                  }
                } catch (e) {
                  // Handle JSON parse errors
                  controller.addError(e);
                }
              }
            },
            onDone: () {
              if (!controller.isClosed) controller.close();
            },
            onError: (error) {
              controller.addError(error);
              controller.close();
            },
            cancelOnError: false,
          );
    } catch (e) {
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }

  Future<void> updateSessionTitle(
    String sessionId,
    String userId,
    String newTitle,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions/$sessionId');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'title': newTitle}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update session title: ${response.statusCode} ${response.body}',
        );
      }

      // Update local Hive storage
      final session = _sessionBox.get(sessionId);
      if (session != null) {
        final updatedSession = ChatSessionHive(
          sessionId: session.sessionId,
          userId: session.userId,
          title: newTitle,
          model: session.model,
          createdAt: session.createdAt,
          updatedAt: DateTime.now(),
        );
        await _sessionBox.put(sessionId, updatedSession);
      }
    } catch (e) {
      throw Exception('Error updating session title: $e');
    }
  }

  Future<void> updateSessionModel(
    String sessionId,
    String userId,
    String newModel,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/chat/sessions/$sessionId');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'model': newModel,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update model: ${response.statusCode} ${response.body}',
      );
    }
    final old = _sessionBox.get(sessionId);
    if (old != null) {
      final updated = ChatSessionHive(
        sessionId: old.sessionId,
        userId: old.userId,
        title: old.title,
        model: newModel,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      await _sessionBox.put(sessionId, updated);
    }
  }
}
