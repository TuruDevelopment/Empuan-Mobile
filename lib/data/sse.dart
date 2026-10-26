import 'dart:convert';

/// One Server-Sent Events message.
class SseEvent {
  const SseEvent(this.event, this.data);

  /// The `event:` name, or `message` when the server sent none.
  final String event;

  /// Every `data:` line of the event, joined with `\n`.
  final String data;

  @override
  String toString() => 'SseEvent($event, $data)';
}

/// Splits a raw byte stream into [SseEvent]s.
///
/// Bytes are decoded as UTF-8 before lines are split, so a chunk boundary in
/// the middle of a character or a CRLF pair is fine. Handles `\n`, `\r\n` and
/// `\r` line endings, multi-line `data`, comments, and a final event that is
/// missing its blank line.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var event = '';
  final data = <String>[];
  var first = true;

  await for (var line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (first) {
      first = false;
      if (line.startsWith('﻿')) line = line.substring(1);
    }
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseEvent(event.isEmpty ? 'message' : event, data.join('\n'));
      event = '';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;

    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        data.add(value);
    }
  }
  if (data.isNotEmpty) yield SseEvent(event.isEmpty ? 'message' : event, data.join('\n'));
}
