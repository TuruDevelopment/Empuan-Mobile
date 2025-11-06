class ChatMessage {
  final int id;
  final String role; // 'user' or 'assistant'
  final String message;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      role: json['role'] ?? 'user',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  ChatMessage copyWith({
    int? id,
    String? role,
    String? message,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatSession {
  final String sessionId;
  final String preview;
  final int messageCount;
  final DateTime firstMessage;
  final DateTime lastMessage;

  ChatSession({
    required this.sessionId,
    required this.preview,
    required this.messageCount,
    required this.firstMessage,
    required this.lastMessage,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'] ?? '',
      preview: json['preview'] ?? '',
      messageCount: json['message_count'] ?? 0,
      firstMessage: DateTime.parse(json['first_message']),
      lastMessage: DateTime.parse(json['last_message']),
    );
  }
}
