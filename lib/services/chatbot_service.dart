import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/api.dart';
import '../data/sse.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

/// What [ChatbotService.stream] and [ChatbotService.regenerate] emit, in
/// this order: [ChatMetaEvent], any mix of [ChatStatusEvent] and
/// [ChatDeltaEvent], then exactly one [ChatDoneEvent] or [ChatErrorEvent].
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// The chat's session id; new chats get theirs here.
class ChatMetaEvent extends ChatStreamEvent {
  const ChatMetaEvent(this.sessionId);

  final String sessionId;
}

/// The AI is running a tool, e.g. "Looking for courses".
class ChatStatusEvent extends ChatStreamEvent {
  const ChatStatusEvent({required this.tool, required this.label});

  final String tool;
  final String label;
}

/// The next piece of the answer text.
class ChatDeltaEvent extends ChatStreamEvent {
  const ChatDeltaEvent(this.text);

  final String text;
}

/// The answer is saved. [assistantMessage] holds the final text, which wins
/// over the streamed deltas.
class ChatDoneEvent extends ChatStreamEvent {
  const ChatDoneEvent({required this.assistantMessage, this.userMessage, this.title, this.blockedScope = false});

  /// Null when an old backend answered without it.
  final ChatMessage? userMessage;
  final ChatMessage assistantMessage;
  final String? title;

  /// The question was outside what Empuan AI answers.
  final bool blockedScope;
}

/// Nothing was saved. Retrying with the same text won't duplicate anything.
class ChatErrorEvent extends ChatStreamEvent {
  const ChatErrorEvent(this.error);

  final ApiException error;
}

/// Empuan AI. Request failures are thrown as [ApiException] so screens can
/// show them as errors, never as an assistant reply; streams end with a
/// [ChatErrorEvent] instead of throwing.
class ChatbotService {
  ChatbotService({
    Api? api,
    http.Client? client,
    this.firstByteTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _api = api ?? Api(client: client);

  final http.Client _client;
  final Api _api;

  /// How long a streamed answer may take to start.
  final Duration firstByteTimeout;

  /// How long a streamed answer may go quiet. Pings and status events count
  /// as activity.
  final Duration idleTimeout;

  static const _timedOut = ApiException('Empuan AI took too long to answer. Please try again.', code: 'ai_timeout');
  static const _offline = ApiException('Can’t reach Empuan right now. Check your internet and try again.');
  static const _interrupted = ApiException('The connection dropped before the answer finished. Please try again.');
  static const _noAnswer = ApiException('Empuan AI couldn’t answer this time. Please try again.');

  /// Kept for older flows; [stream] creates the session itself.
  Future<String> createNewSession() async {
    final data = asMap(asMap(await _api.post(ApiConfig.chatbotNewSession))['data']);
    final id = asString(data['session_id']);
    if (id.isEmpty) throw const ApiException('Couldn’t start a new chat. Please try again.');
    return id;
  }

  /// Returns the assistant's answer, without streaming.
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
    if (json['success'] == false || answer.isEmpty) throw _noAnswer;
    return answer;
  }

  /// Sends [message] and streams the answer. Without [sessionId] the server
  /// starts a new chat and reports its id in [ChatMetaEvent].
  ///
  /// Falls back to `/chatbot/send` on a backend without streaming.
  Stream<ChatStreamEvent> stream({required String message, String? sessionId, bool useHistory = true}) {
    return _events(
      ApiConfig.chatbotStream,
      {'message': message, 'session_id': sessionId, 'use_history': useHistory},
      sessionId: sessionId,
      fallback: () => _sendEvents(message: message, sessionId: sessionId, useHistory: useHistory),
    );
  }

  /// Streams a new answer to the session's last question; the server swaps
  /// it in for the old one only when it succeeds.
  ///
  /// On a backend without this route, [question] is sent again instead.
  Stream<ChatStreamEvent> regenerate(String sessionId, {String? question}) {
    return _events(
      ApiConfig.chatbotRegenerate(sessionId),
      const {},
      sessionId: sessionId,
      fallback: question == null ? null : () => stream(message: question, sessionId: sessionId),
    );
  }

  /// Rates an assistant answer; null clears the rating. Returns the rating
  /// the server stored.
  Future<ChatFeedback?> sendFeedback(int messageId, ChatFeedback? rating, {String? reason}) async {
    final note = reason?.trim() ?? '';
    final json = asMap(await _api.post(ApiConfig.chatbotFeedback(messageId), body: {
      'rating': rating?.name,
      if (note.isNotEmpty) 'reason': note.length > 500 ? note.substring(0, 500) : note,
    }));
    final data = asMap(json['data']);
    return data.containsKey('feedback') ? ChatFeedback.parse(data['feedback']) : rating;
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

  Stream<ChatStreamEvent> _events(
    String path,
    Map<String, dynamic> body, {
    String? sessionId,
    Stream<ChatStreamEvent> Function()? fallback,
  }) async* {
    // Completing this closes the connection, e.g. when the listener cancels.
    final abort = Completer<void>();
    final clock = Stopwatch()..start();
    try {
      final request = http.AbortableRequest('POST', Uri.parse(ApiConfig.getUrl(path)), abortTrigger: abort.future)
        ..headers.addAll({...AuthService.getAuthHeaders(), 'Accept': 'text/event-stream'})
        ..body = jsonEncode(body);

      final http.StreamedResponse response;
      try {
        response = await _client.send(request).timeout(firstByteTimeout);
      } on TimeoutException {
        yield const ChatErrorEvent(_timedOut);
        return;
      } catch (_) {
        yield const ChatErrorEvent(_offline);
        return;
      }

      final status = response.statusCode;
      final ok = status >= 200 && status < 300;
      if (!ok || (response.headers['content-type'] ?? '').contains('json')) {
        // Errors arrive before streaming starts, as small JSON bodies.
        final dynamic decoded;
        try {
          decoded = _decode(utf8.decode(await response.stream.toBytes().timeout(firstByteTimeout), allowMalformed: true));
        } on TimeoutException {
          yield const ChatErrorEvent(_timedOut);
          return;
        } catch (_) {
          yield const ChatErrorEvent(_offline);
          return;
        }
        if (ok) {
          yield* _replyEvents(asMap(decoded), sessionId);
          return;
        }
        if (status == 401) {
          await AuthService.handleSessionExpired();
          yield const ChatErrorEvent(ApiException('Your session has ended. Please log in again.', statusCode: 401, retryable: false));
          return;
        }
        final error = ApiException.fromResponse(status, decoded, headers: response.headers);
        // An old backend has no streaming route: answer through /send.
        if (fallback != null && error.code == null && (status == 404 || status == 405)) {
          yield* fallback();
          return;
        }
        yield ChatErrorEvent(error);
        return;
      }

      final text = StringBuffer();
      final firstWait = firstByteTimeout - clock.elapsed;
      try {
        final bytes = _guard(response.stream, first: firstWait.isNegative ? Duration.zero : firstWait, idle: idleTimeout);
        await for (final event in parseSse(bytes)) {
          final data = asMap(_decode(event.data));
          switch (event.event) {
            case 'meta':
              final id = asString(data['session_id'], sessionId ?? '');
              if (id.isNotEmpty) yield ChatMetaEvent(id);
            case 'status':
              yield ChatStatusEvent(tool: asString(data['tool']), label: asString(data['label']).trim());
            case 'delta':
              final piece = asString(data['text']);
              if (piece.isEmpty) continue;
              text.write(piece);
              yield ChatDeltaEvent(piece);
            case 'done':
              yield _done(data, streamed: text.toString());
              return;
            case 'error':
              yield ChatErrorEvent(_streamError(data));
              return;
          }
        }
      } on TimeoutException {
        yield const ChatErrorEvent(_timedOut);
        return;
      } catch (_) {
        yield const ChatErrorEvent(_interrupted);
        return;
      }
      // The connection closed without `done` or `error`.
      yield const ChatErrorEvent(_interrupted);
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  /// Answers through `/chatbot/send` and replays the reply as events.
  Stream<ChatStreamEvent> _sendEvents({required String message, String? sessionId, required bool useHistory}) async* {
    try {
      // Old backends expect the session to exist before the first message.
      final id = sessionId ?? await createNewSession();
      final json = await _api.post(ApiConfig.chatbotSend, body: {
        'message': message,
        'session_id': id,
        'use_history': useHistory,
      });
      yield* _replyEvents(asMap(json), id);
    } on ApiException catch (e) {
      yield ChatErrorEvent(e);
    }
  }

  /// A `/chatbot/send`-style JSON reply as meta, one delta and done. Reads
  /// the v2 shape and the old one that only has `response`.
  Stream<ChatStreamEvent> _replyEvents(Map<String, dynamic> json, String? sessionId) async* {
    final data = asMap(json['data']);
    final done = _done(data, streamed: asString(data['response']).trim());
    if (json['success'] == false || done is! ChatDoneEvent) {
      yield done is ChatErrorEvent ? done : const ChatErrorEvent(_noAnswer);
      return;
    }
    final id = asString(data['session_id'], sessionId ?? '');
    if (id.isNotEmpty) yield ChatMetaEvent(id);
    yield ChatDeltaEvent(done.assistantMessage.text);
    yield done;
  }

  /// [streamed] stands in for the answer text when the server left it out.
  static ChatStreamEvent _done(Map<String, dynamic> data, {required String streamed}) {
    final saved = data['assistant_message'];
    var assistant = saved is Map ? ChatMessage.fromJson({...asMap(saved), 'role': 'assistant'}) : null;
    if (assistant == null || assistant.text.trim().isEmpty) {
      if (streamed.trim().isEmpty) return const ChatErrorEvent(_noAnswer);
      assistant = assistant == null
          ? ChatMessage.assistant(streamed)
          : ChatMessage.fromJson({...asMap(saved), 'role': 'assistant', 'message': streamed});
    }
    final user = data['user_message'];
    final title = asString(data['title']).trim();
    return ChatDoneEvent(
      userMessage: user is Map ? ChatMessage.fromJson({...asMap(user), 'role': 'user'}) : null,
      assistantMessage: assistant,
      title: title.isEmpty ? null : title,
      blockedScope: asBool(data['blocked_scope']),
    );
  }

  static ApiException _streamError(Map<String, dynamic> data) {
    final code = asString(data['code']);
    final seconds = asInt(data['retry_after'], -1);
    return ApiException(
      asString(data['message'], _noAnswer.message),
      code: code.isEmpty ? null : code,
      retryable: data.containsKey('retryable') ? asBool(data['retryable']) : true,
      retryAfter: seconds < 0 ? null : Duration(seconds: seconds),
    );
  }

  static dynamic _decode(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Passes [source] through, failing with [TimeoutException] when the first
  /// chunk takes longer than [first] or a later one longer than [idle].
  static Stream<List<int>> _guard(Stream<List<int>> source, {required Duration first, required Duration idle}) {
    StreamSubscription<List<int>>? sub;
    Timer? timer;
    late final StreamController<List<int>> out;

    void arm(Duration wait) {
      timer?.cancel();
      timer = Timer(wait, () {
        out.addError(TimeoutException('No data for $wait'));
        unawaited(sub?.cancel());
        unawaited(out.close());
      });
    }

    out = StreamController<List<int>>(
      onListen: () {
        arm(first);
        sub = source.listen(
          (chunk) {
            arm(idle);
            out.add(chunk);
          },
          onError: out.addError,
          onDone: () {
            timer?.cancel();
            unawaited(out.close());
          },
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return out.stream;
  }
}
