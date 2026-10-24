import 'dart:async';
import 'dart:convert';

import 'package:Empuan/data/api.dart';
import 'package:Empuan/models/chat_message.dart';
import 'package:Empuan/services/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sse = {'content-type': 'text/event-stream'};

String sse(String event, Object data) => 'event: $event\ndata: ${jsonEncode(data)}\n\n';

Map<String, dynamic> message(int id, String role, String text, {List<Map<String, dynamic>> actions = const []}) => {
      'id': id,
      'role': role,
      'message': text,
      'timestamp': '2026-10-23T10:00:00Z',
      'feedback': null,
      'actions': actions,
      'truncated': false,
    };

http.StreamedResponse streamed(Stream<String> body, [int status = 200, Map<String, String> headers = _sse]) =>
    http.StreamedResponse(body.map(utf8.encode), status, headers: headers);

http.StreamedResponse jsonResponse(Object body, int status) =>
    http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(body))), status, headers: {'content-type': 'application/json'});

ChatbotService serviceWith(
  Future<http.StreamedResponse> Function(http.BaseRequest request, String body) handler, {
  Duration firstByte = const Duration(seconds: 30),
  Duration idle = const Duration(seconds: 20),
}) {
  return ChatbotService(
    client: MockClient.streaming((request, body) async => handler(request, await body.bytesToString())),
    firstByteTimeout: firstByte,
    idleTimeout: idle,
  );
}

void main() {
  test('streams meta, status, deltas and done', () async {
    late http.BaseRequest sent;
    late Map<String, dynamic> body;
    final service = serviceWith((request, raw) async {
      sent = request;
      body = jsonDecode(raw) as Map<String, dynamic>;
      return streamed(Stream.fromIterable([
        sse('meta', {'session_id': 'abc'}),
        ': ping\n\n',
        sse('status', {'tool': 'search_courses', 'label': 'Looking for courses'}),
        sse('delta', {'text': 'Try '}),
        sse('delta', {'text': 'this course.'}),
        sse('done', {
          'user_message': message(811, 'user', 'How do I budget?'),
          'assistant_message': message(812, 'assistant', 'Try this course.', actions: [
            {'type': 'course', 'label': 'Open Budgeting basics', 'slug': 'budgeting-basics'},
          ]),
          'title': 'Budgeting help',
          'blocked_scope': false,
        }),
      ]));
    });

    final events = await service.stream(message: 'How do I budget?').toList();

    expect(sent.url.path, endsWith('/chatbot/stream'));
    expect(sent.method, 'POST');
    expect(sent.headers['Accept'], 'text/event-stream');
    expect(body, {'message': 'How do I budget?', 'session_id': null, 'use_history': true});
    expect(events.map((e) => e.runtimeType), [ChatMetaEvent, ChatStatusEvent, ChatDeltaEvent, ChatDeltaEvent, ChatDoneEvent]);
    expect((events[0] as ChatMetaEvent).sessionId, 'abc');
    expect((events[1] as ChatStatusEvent).label, 'Looking for courses');
    final done = events.last as ChatDoneEvent;
    expect(done.userMessage?.id, 811);
    expect(done.assistantMessage.id, 812);
    expect(done.assistantMessage.isUser, isFalse);
    expect(done.assistantMessage.actions.single.slug, 'budgeting-basics');
    expect(done.title, 'Budgeting help');
  });

  test('the text in done wins over the streamed deltas', () async {
    final service = serviceWith((_, __) async => streamed(Stream.fromIterable([
          sse('meta', {'session_id': 'abc'}),
          sse('delta', {'text': 'Sure, the best crypto'}),
          sse('done', {
            'user_message': message(1, 'user', 'Which crypto?'),
            'assistant_message': message(2, 'assistant', 'I can only help with safety, work, money and wellbeing.'),
            'title': null,
            'blocked_scope': true,
          }),
        ])));

    final done = (await service.stream(message: 'Which crypto?').toList()).last as ChatDoneEvent;

    expect(done.assistantMessage.text, 'I can only help with safety, work, money and wellbeing.');
    expect(done.blockedScope, isTrue);
  });

  test('an error event mid-stream ends the stream without done', () async {
    final service = serviceWith((_, __) async => streamed(Stream.fromIterable([
          sse('meta', {'session_id': 'abc'}),
          sse('delta', {'text': 'Part'}),
          sse('error', {'code': 'blocked', 'message': 'Empuan AI can’t answer that.', 'retryable': false}),
        ])));

    final events = await service.stream(message: 'Hi', sessionId: 'abc').toList();

    final error = (events.last as ChatErrorEvent).error;
    expect(events.whereType<ChatDoneEvent>(), isEmpty);
    expect(error.code, 'blocked');
    expect(error.retryable, isFalse);
  });

  test('a connection that closes before done is a retryable error', () async {
    final service = serviceWith((_, __) async => streamed(Stream.value(sse('delta', {'text': 'Half'}))));

    final last = (await service.stream(message: 'Hi').toList()).last;

    expect(last, isA<ChatErrorEvent>().having((e) => e.error.retryable, 'retryable', isTrue));
  });

  group('errors before streaming starts', () {
    test('429 carries the code and when to try again', () async {
      final service = serviceWith((_, __) async => jsonResponse(
          {'success': false, 'code': 'rate_limited', 'message': 'Slow down.', 'retryable': true, 'retry_after': 40}, 429));

      final error = ((await service.stream(message: 'Hi').toList()).single as ChatErrorEvent).error;

      expect(error.statusCode, 429);
      expect(error.code, 'rate_limited');
      expect(error.retryable, isTrue);
      expect(error.retryAfter, const Duration(seconds: 40));
    });

    test('422 blocked is not retryable', () async {
      final service = serviceWith((_, __) async =>
          jsonResponse({'success': false, 'code': 'blocked', 'message': 'Can’t answer.', 'retryable': false}, 422));

      final error = ((await service.stream(message: 'Hi').toList()).single as ChatErrorEvent).error;

      expect(error.code, 'blocked');
      expect(error.retryable, isFalse);
      expect(error.message, 'Can’t answer.');
    });

    test('503 ai_unavailable is retryable', () async {
      final service = serviceWith((_, __) async =>
          jsonResponse({'success': false, 'code': 'ai_unavailable', 'message': 'Try later.', 'retryable': true}, 503));

      final error = ((await service.stream(message: 'Hi').toList()).single as ChatErrorEvent).error;

      expect(error.code, 'ai_unavailable');
      expect(error.retryable, isTrue);
    });

    test('404 not_found is an error, not a reason to fall back', () async {
      var calls = 0;
      final service = serviceWith((_, __) async {
        calls++;
        return jsonResponse({'success': false, 'code': 'not_found', 'message': 'Chat not found.', 'retryable': false}, 404);
      });

      final error = ((await service.stream(message: 'Hi', sessionId: 'x').toList()).single as ChatErrorEvent).error;

      expect(error.code, 'not_found');
      expect(calls, 1);
    });
  });

  group('timeouts', () {
    test('no response in time is ai_timeout', () async {
      final never = Completer<http.StreamedResponse>();
      final service = serviceWith((_, __) => never.future, firstByte: const Duration(milliseconds: 50));

      final error = ((await service.stream(message: 'Hi').toList()).single as ChatErrorEvent).error;

      expect(error.code, 'ai_timeout');
      expect(error.retryable, isTrue);
    });

    test('a stream that goes quiet is ai_timeout', () async {
      final body = StreamController<String>();
      addTearDown(body.close);
      body.add(sse('meta', {'session_id': 'abc'}));
      final service = serviceWith((_, __) async => streamed(body.stream), idle: const Duration(milliseconds: 60));

      final events = await service.stream(message: 'Hi').toList();

      expect(events.first, isA<ChatMetaEvent>());
      expect((events.last as ChatErrorEvent).error.code, 'ai_timeout');
    });

    test('pings and status events keep a slow answer alive', () async {
      final service = serviceWith(
        (_, __) async => streamed(() async* {
          yield sse('meta', {'session_id': 'abc'});
          for (var i = 0; i < 4; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 40));
            yield i.isEven ? ': ping\n\n' : sse('status', {'tool': 'find_places', 'label': 'Looking for places'});
          }
          yield sse('delta', {'text': 'Done.'});
          yield sse('done', {'assistant_message': message(2, 'assistant', 'Done.')});
        }()),
        idle: const Duration(milliseconds: 100),
      );

      final events = await service.stream(message: 'Hi').toList();

      expect(events.last, isA<ChatDoneEvent>());
    });
  });

  group('fallback to /chatbot/send', () {
    test('uses the v2 JSON shape when the stream route is missing', () async {
      final paths = <String>[];
      final service = serviceWith((request, raw) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/chatbot/stream')) return jsonResponse({'message': 'Route not found.'}, 404);
        expect(jsonDecode(raw), {'message': 'Hi', 'session_id': 'abc', 'use_history': true});
        return jsonResponse({
          'success': true,
          'data': {
            'session_id': 'abc',
            'title': 'Greeting',
            'user_message': message(5, 'user', 'Hi'),
            'assistant_message': message(6, 'assistant', 'Hello!', actions: [
              {'type': 'place', 'label': 'See Ruang Kerja Puan', 'id': 4},
            ]),
            'response': 'Hello!',
            'blocked_scope': false,
          },
        }, 200);
      });

      final events = await service.stream(message: 'Hi', sessionId: 'abc').toList();

      expect(paths.map((p) => p.split('/api').last), ['/chatbot/stream', '/chatbot/send']);
      expect(events.map((e) => e.runtimeType), [ChatMetaEvent, ChatDeltaEvent, ChatDoneEvent]);
      expect((events[1] as ChatDeltaEvent).text, 'Hello!');
      final done = events.last as ChatDoneEvent;
      expect(done.assistantMessage.id, 6);
      expect(done.assistantMessage.actions.single.type, ChatActionType.place);
      expect(done.title, 'Greeting');
    });

    test('reads the old shape and creates the session first', () async {
      final paths = <String>[];
      final service = serviceWith((request, raw) async {
        final path = request.url.path;
        paths.add(path);
        if (path.endsWith('/chatbot/stream')) return jsonResponse({'message': 'Method not allowed.'}, 405);
        if (path.endsWith('/chatbot/sessions/new')) return jsonResponse({'success': true, 'data': {'session_id': 'new-1'}}, 200);
        expect(jsonDecode(raw)['session_id'], 'new-1');
        return jsonResponse({'success': true, 'data': {'response': 'Old answer'}}, 200);
      });

      final events = await service.stream(message: 'Hi').toList();

      expect(paths.last, endsWith('/chatbot/send'));
      expect((events.first as ChatMetaEvent).sessionId, 'new-1');
      final done = events.last as ChatDoneEvent;
      expect(done.assistantMessage.text, 'Old answer');
      expect(done.assistantMessage.id, isNull);
      expect(done.userMessage, isNull);
    });

    test('regenerate re-sends the question on a backend without the route', () async {
      final paths = <String>[];
      final service = serviceWith((request, raw) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/regenerate') || request.url.path.endsWith('/stream')) {
          return jsonResponse({'message': 'Not found'}, 404);
        }
        return jsonResponse({'success': true, 'data': {'response': 'Another answer'}}, 200);
      });

      final events = await service.regenerate('abc', question: 'Hi').toList();

      expect(paths.map((p) => p.split('/api').last), ['/chatbot/sessions/abc/regenerate', '/chatbot/stream', '/chatbot/send']);
      expect((events.last as ChatDoneEvent).assistantMessage.text, 'Another answer');
    });
  });

  test('regenerate streams from the session route', () async {
    late http.BaseRequest sent;
    final service = serviceWith((request, raw) async {
      sent = request;
      expect(jsonDecode(raw), <String, dynamic>{});
      return streamed(Stream.fromIterable([
        sse('meta', {'session_id': 'abc'}),
        sse('delta', {'text': 'New'}),
        sse('done', {'user_message': message(1, 'user', 'Q'), 'assistant_message': message(9, 'assistant', 'New')}),
      ]));
    });

    final done = (await service.regenerate('abc').toList()).last as ChatDoneEvent;

    expect(sent.url.path, endsWith('/chatbot/sessions/abc/regenerate'));
    expect(done.assistantMessage.id, 9);
  });

  test('sendFeedback posts the rating and reason', () async {
    late Map<String, dynamic> body;
    final service = ChatbotService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/chatbot/messages/812/feedback'));
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'success': true, 'data': {'id': 812, 'feedback': 'down'}}), 200);
      }),
    );

    final stored = await service.sendFeedback(812, ChatFeedback.down, reason: 'Not accurate');

    expect(body, {'rating': 'down', 'reason': 'Not accurate'});
    expect(stored, ChatFeedback.down);
  });

  test('sendFeedback with null clears the rating', () async {
    late Map<String, dynamic> body;
    final service = ChatbotService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'success': true, 'data': {'id': 812, 'feedback': null}}), 200);
      }),
    );

    expect(await service.sendFeedback(812, null), isNull);
    expect(body, {'rating': null});
  });

  test('ApiException reads the chatbot error shape', () {
    final e = ApiException.fromResponse(429, {'code': 'rate_limited', 'message': 'Wait.', 'retryable': true}, headers: {'retry-after': '90'});

    expect(e.message, 'Wait.');
    expect(e.retryAfter, const Duration(seconds: 90));
    expect(e.notAvailable, isFalse);
    expect(const ApiException('x', statusCode: 404).notAvailable, isTrue);
  });
}
