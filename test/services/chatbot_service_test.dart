import 'dart:convert';

import 'package:Empuan/services/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('getHistory loads every page in chronological order', () async {
    final requestedUrls = <String>[];

    final service = ChatbotService(
      getRequest: (url) async {
        requestedUrls.add(url);
        final page = Uri.parse(url).queryParameters['page'];

        if (page == '1') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'history': [
                  {
                    'id': 1,
                    'role': 'user',
                    'message': 'Pertanyaan pertama',
                    'timestamp': '2026-07-30T10:00:00.000Z',
                  },
                  {
                    'id': 2,
                    'role': 'assistant',
                    'message': 'Jawaban pertama',
                    'timestamp': '2026-07-30T10:00:01.000Z',
                  },
                ],
              },
              'meta': {'last_page': 2},
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'history': [
                {
                  'id': 3,
                  'role': 'user',
                  'message': 'Pertanyaan kedua',
                  'timestamp': '2026-07-30T10:01:00.000Z',
                },
                {
                  'id': 4,
                  'role': 'assistant',
                  'message': 'Jawaban kedua',
                  'timestamp': '2026-07-30T10:01:01.000Z',
                },
              ],
            },
            'meta': {'last_page': 2},
          }),
          200,
        );
      },
    );

    final history = await service.getHistory('session-123');

    expect(history.map((message) => message.id), [1, 2, 3, 4]);
    expect(
      history.map((message) => message.role),
      ['user', 'assistant', 'user', 'assistant'],
    );
    expect(requestedUrls, hasLength(2));
    expect(requestedUrls[0], contains('per_page=100&page=1'));
    expect(requestedUrls[1], contains('per_page=100&page=2'));
  });
}
