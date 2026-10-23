import '../config/api_config.dart';
import '../data/api.dart';
import '../models/chat_message.dart';

/// Empuan AI. Every failure is thrown as [ApiException] so screens can show
/// it as an error, never as an assistant reply.
class ChatbotService {
  ChatbotService({Api? api}) : _api = api ?? Api();

  final Api _api;

  Future<String> createNewSession() async {
    final data = asMap(asMap(await _api.post(ApiConfig.chatbotNewSession))['data']);
    final id = asString(data['session_id']);
    if (id.isEmpty) throw const ApiException('Couldn’t start a new chat. Please try again.');
    return id;
  }

  /// Returns the assistant's answer.
  Future<String> sendMessage({
    required String message,
    required String sessionId,
    bool useHistory = true,
  }) async {
    final json = asMap(await _api.post(ApiConfig.chatbotSend, body: {
      'message': message,
      'session_id': sessionId,
      'use_history': useHistory,
    }));
    final answer = asString(asMap(json['data'])['response']).trim();
    if (json['success'] == false || answer.isEmpty) {
      throw const ApiException('Empuan AI couldn’t answer this time. Please try again.');
    }
    return answer;
  }

  /// Most recent first.
  Future<List<ChatSession>> getSessions() async {
    final sessions = asMapList(await _api.get(ApiConfig.chatbotSessions))
        .map(ChatSession.fromJson)
        .where((s) => s.sessionId.isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastMessage.compareTo(a.lastMessage));
    return sessions;
  }

  /// The whole conversation in chronological order, across all pages.
  Future<List<ChatMessage>> getHistory(String sessionId) async {
    final history = <ChatMessage>[];
    var page = 1;
    var lastPage = 1;
    do {
      final json = asMap(await _api.get(
        ApiConfig.chatbotHistory(sessionId),
        query: {'per_page': '100', 'page': '$page'},
      ));
      history.addAll(asMapList(asMap(json['data'])['history']).map(ChatMessage.fromJson));
      lastPage = asInt(asMap(json['meta'])['last_page'], 1);
      page++;
    } while (page <= lastPage);
    return history;
  }

  Future<void> deleteSession(String sessionId) async {
    final json = asMap(await _api.delete(ApiConfig.chatbotDeleteSession(sessionId)));
    if (json['success'] == false) {
      throw ApiException(asString(json['message'], 'Couldn’t delete this chat. Please try again.'));
    }
  }
}
