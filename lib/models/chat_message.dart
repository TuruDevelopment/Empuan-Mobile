import '../data/api.dart';
import '../ui/em_ui.dart' show parseDate;

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.id,
  });

  /// Server id; null for messages sent in this visit.
  final int? id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.user(String text) => ChatMessage(role: ChatRole.user, text: text, timestamp: DateTime.now());

  factory ChatMessage.assistant(String text) =>
      ChatMessage(role: ChatRole.assistant, text: text, timestamp: DateTime.now());

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] == null ? null : asInt(json['id']),
      role: asString(json['role']) == 'assistant' ? ChatRole.assistant : ChatRole.user,
      text: asString(json['message']),
      timestamp: parseDate(json['timestamp']) ?? DateTime.now(),
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.sessionId,
    required this.preview,
    required this.messageCount,
    required this.lastMessage,
    this.title,
  });

  final String sessionId;

  /// Server-generated title, when the backend provides one.
  final String? title;

  /// The first user message.
  final String preview;
  final int messageCount;
  final DateTime lastMessage;

  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final p = preview.trim();
    return p.isEmpty ? 'Untitled chat' : p;
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final title = asString(json['title']);
    return ChatSession(
      sessionId: asString(json['session_id']),
      title: title.isEmpty ? null : title,
      preview: asString(json['preview']),
      messageCount: asInt(json['message_count']),
      lastMessage: parseDate(json['last_message'] ?? json['first_message']) ?? DateTime.now(),
    );
  }
}
