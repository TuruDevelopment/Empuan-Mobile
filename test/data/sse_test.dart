import 'dart:convert';

import 'package:Empuan/data/sse.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<SseEvent>> parseChunks(List<List<int>> chunks) => parseSse(Stream.fromIterable(chunks)).toList();

List<int> bytes(String s) => utf8.encode(s);

void main() {
  test('parses named events and joins multi-line data', () async {
    final events = await parseChunks([bytes('event: meta\ndata: {"a":1}\n\nevent: delta\ndata: line one\ndata: line two\n\n')]);

    expect(events.map((e) => e.event), ['meta', 'delta']);
    expect(events.first.data, '{"a":1}');
    expect(events.last.data, 'line one\nline two');
  });

  test('handles lines split across chunks and CRLF split between chunks', () async {
    final events = await parseChunks([
      bytes('event: del'),
      bytes('ta\r'),
      bytes('\ndata: {"text":"Hel'),
      bytes('lo"}\r\n\r'),
      bytes('\n'),
    ]);

    expect(events, hasLength(1));
    expect(events.single.event, 'delta');
    expect(jsonDecode(events.single.data), {'text': 'Hello'});
  });

  test('ignores comments and pings, and fields without a value', () async {
    final events = await parseChunks([bytes(': ping\n\n:another comment\nevent: status\nid\ndata: {"label":"Looking for courses"}\n\n')]);

    expect(events, hasLength(1));
    expect(events.single.event, 'status');
    expect(jsonDecode(events.single.data)['label'], 'Looking for courses');
  });

  test('decodes a UTF-8 character split between chunks', () async {
    final all = bytes('event: delta\ndata: {"text":"Halo 👋 ibu"}\n\n');
    final wave = all.indexOf(0xF0);
    final events = await parseChunks([all.sublist(0, wave + 2), all.sublist(wave + 2)]);

    expect(jsonDecode(events.single.data)['text'], 'Halo 👋 ibu');
  });

  test('dispatches a final event that is missing its blank line', () async {
    final events = await parseChunks([bytes('data: last')]);

    expect(events.single.event, 'message');
    expect(events.single.data, 'last');
  });
}
