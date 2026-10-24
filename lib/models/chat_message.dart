import '../data/api.dart';
import '../ui/em_ui.dart' show parseDate;

enum ChatRole { user, assistant }

/// The user's rating of an answer.
enum ChatFeedback {
  up,
  down;

  static ChatFeedback? parse(dynamic value) => switch (asString(value)) {
        'up' => ChatFeedback.up,
        'down' => ChatFeedback.down,
        _ => null,
      };
}

/// In-app shortcut the AI suggested under an answer.
enum ChatActionType {
  sos('sos'),
  fakeCall('fake_call'),
  trustedContacts('trusted_contacts'),
  siren('siren'),
  course('course'),
  article('article'),
  place('place'),

  /// Course search, sent when no course matched.
  learn('learn'),

  /// Place search, sent when no place matched.
  places('places');

  const ChatActionType(this.wire);

  final String wire;

  static ChatActionType? parse(dynamic value) {
    final s = asString(value);
    for (final t in values) {
      if (t.wire == s) return t;
    }
    return null;
  }
}

class ChatAction {
  const ChatAction({required this.type, required this.label, this.slug, this.id, this.query});

  final ChatActionType type;
  final String label;

  /// Course slug, for [ChatActionType.course].
  final String? slug;

  /// Article or place id, for [ChatActionType.article] and [ChatActionType.place].
  final int? id;

  /// Search text, for [ChatActionType.learn] and [ChatActionType.places].
  final String? query;

  /// Null for types this version of the app doesn't know, or when the field
  /// the type needs is missing.
  static ChatAction? fromJson(Map<String, dynamic> json) {
    final type = ChatActionType.parse(json['type']);
    if (type == null) return null;
    final slug = asString(json['slug']).trim();
    final id = asInt(json['id']);
    if (type == ChatActionType.course && slug.isEmpty) return null;
    if ((type == ChatActionType.article || type == ChatActionType.place) && id <= 0) return null;
    final label = asString(json['label']).trim();
    final query = asString(json['query']).trim();
    return ChatAction(
      type: type,
      label: label.isEmpty ? _defaultLabel(type) : label,
      slug: slug.isEmpty ? null : slug,
      id: id > 0 ? id : null,
      query: query.isEmpty ? null : query,
    );
  }

  static String _defaultLabel(ChatActionType type) => switch (type) {
        ChatActionType.sos => 'How SOS works',
        ChatActionType.fakeCall => 'Start a fake call',
        ChatActionType.trustedContacts => 'Set up trusted contacts',
        ChatActionType.siren => 'Open the siren',
        ChatActionType.course => 'Open course',
        ChatActionType.article => 'Read article',
        ChatActionType.place => 'See place',
        ChatActionType.learn => 'Browse courses',
        ChatActionType.places => 'Browse places',
      };
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.id,
    this.feedback,
    this.actions = const [],
    this.truncated = false,
  });

  /// Server id; null for messages not saved yet.
  final int? id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  /// The user's rating; only on assistant messages.
  final ChatFeedback? feedback;

  /// Up to three shortcuts shown under an assistant answer.
  final List<ChatAction> actions;

  /// The answer hit the length limit and stops mid-way.
  final bool truncated;

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.user(String text) => ChatMessage(role: ChatRole.user, text: text, timestamp: DateTime.now());

  factory ChatMessage.assistant(String text) => ChatMessage(role: ChatRole.assistant, text: text, timestamp: DateTime.now());

  ChatMessage withFeedback(ChatFeedback? value) => ChatMessage(
        id: id,
        role: role,
        text: text,
        timestamp: timestamp,
        feedback: value,
        actions: actions,
        truncated: truncated,
      );

  /// Reads both the full Message object and the older history item that only
  /// has id, role, message and timestamp.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final actions = json['actions'] is List
        ? asMapList(json['actions']).map(ChatAction.fromJson).whereType<ChatAction>().take(3).toList()
        : const <ChatAction>[];
    return ChatMessage(
      id: json['id'] == null ? null : asInt(json['id']),
      role: asString(json['role']) == 'assistant' ? ChatRole.assistant : ChatRole.user,
      text: asString(json['message']),
      timestamp: parseDate(json['timestamp']) ?? DateTime.now(),
      feedback: ChatFeedback.parse(json['feedback']),
      actions: actions,
      truncated: asBool(json['truncated']),
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
