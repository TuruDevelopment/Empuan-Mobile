import 'dart:convert';

import 'package:Empuan/data/api.dart';
import 'package:Empuan/models/chat_message.dart';
import 'package:Empuan/services/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ChatbotService serviceWith(Future<http.Response> Function(http.Request request) handler) {
  return ChatbotService(api: Api(client: MockClient(handler)));
}

http.Response json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

void main() {
  test('getHistory loads every page in chronological order', () async {
    final requested = <Uri>[];
    final service = serviceWith((request) async {
      requested.add(request.url);
      final page = request.url.queryParameters['page'];
      return json({
        'success': true,
        'data': {
          'history': page == '1'
              ? [
                  {'id': 1, 'role': 'user', 'message': 'First question', 'timestamp': '2026-07-30T10:00:00.000Z'},
                  {'id': 2, 'role': 'assistant', 'message': 'First answer', 'timestamp': '2026-07-30T10:00:01.000Z'},
                ]
              : [
                  {'id': 3, 'role': 'user', 'message': 'Second question', 'timestamp': '2026-07-30T10:01:00.000Z'},
                  {'id': 4, 'role': 'assistant', 'message': 'Second answer', 'timestamp': '2026-07-30T10:01:01.000Z'},
                ],
        },
        'meta': {'last_page': 2},
      });
    });

    final history = await service.getHistory('session-123');

    expect(history.map((m) => m.id), [1, 2, 3, 4]);
    expect(history.map((m) => m.role), [ChatRole.user, ChatRole.assistant, ChatRole.user, ChatRole.assistant]);
    expect(requested, hasLength(2));
    expect(requested.every((u) => u.path.endsWith('/chatbot/history/session-123')), isTrue);
    expect(requested.map((u) => u.queryParameters['page']), ['1', '2']);
    expect(requested.first.queryParameters['per_page'], '100');
  });

  test('sendMessage posts the message and returns the answer', () async {
    late Map<String, dynamic> sent;
    final service = serviceWith((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/chatbot/send'));
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return json({
        'success': true,
        'data': {'response': 'Here is what you can do.'},
      });
    });

    final answer = await service.sendMessage(message: 'Hello', sessionId: 'abc');

    expect(answer, 'Here is what you can do.');
    expect(sent, {'message': 'Hello', 'session_id': 'abc', 'use_history': true});
  });

  test('sendMessage throws on a server error instead of returning a fake reply', () async {
    final service = serviceWith((_) async => json({'message': 'Server is busy'}, 503));

    expect(
      service.sendMessage(message: 'Hello', sessionId: 'abc'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503)),
    );
  });

  test('sendMessage throws when the answer is missing', () async {
    final service = serviceWith((_) async => json({'success': false, 'data': null}));

    expect(service.sendMessage(message: 'Hello', sessionId: 'abc'), throwsA(isA<ApiException>()));
  });

  test('createNewSession returns the new session id', () async {
    final service = serviceWith((request) async {
      expect(request.url.path, endsWith('/chatbot/sessions/new'));
      return json({
        'success': true,
        'data': {'session_id': 'new-1'},
      });
    });

    expect(await service.createNewSession(), 'new-1');
  });

  test('getSessions parses sessions, most recent first', () async {
    final service = serviceWith((_) async => json({
          'success': true,
          'data': [
            {
              'session_id': 'old',
              'preview': 'How do I ask for a raise?',
              'message_count': 4,
              'first_message': '2026-10-01T08:00:00Z',
              'last_message': '2026-10-01T08:05:00Z',
            },
            {
              'session_id': 'new',
              'preview': 'Is this loan offer safe?',
              'message_count': 2,
              'first_message': '2026-10-20T08:00:00Z',
              'last_message': '2026-10-20T08:01:00Z',
            },
          ],
        }));

    final sessions = await service.getSessions();

    expect(sessions.map((s) => s.sessionId), ['new', 'old']);
    expect(sessions.last.displayTitle, 'How do I ask for a raise?');
    expect(sessions.last.messageCount, 4);
  });

  test('deleteSession throws when the server refuses', () async {
    final service = serviceWith((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, endsWith('/chatbot/sessions/abc'));
      return json({'message': 'Not found'}, 404);
    });

    expect(service.deleteSession('abc'), throwsA(isA<ApiException>()));
  });

  test('deleteSession completes on success', () async {
    final service = serviceWith((_) async => json({'success': true}));

    await expectLater(service.deleteSession('abc'), completes);
  });
}
