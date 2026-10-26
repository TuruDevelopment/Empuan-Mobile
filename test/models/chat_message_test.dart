import 'package:Empuan/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads an old history item without the v2 fields', () {
    final m = ChatMessage.fromJson({'id': 3, 'role': 'assistant', 'message': 'Hi', 'timestamp': '2026-07-30T10:00:00Z'});

    expect(m.id, 3);
    expect(m.isUser, isFalse);
    expect(m.feedback, isNull);
    expect(m.actions, isEmpty);
    expect(m.truncated, isFalse);
  });

  test('reads feedback, truncated and actions, skipping unknown or incomplete ones', () {
    final m = ChatMessage.fromJson({
      'id': 812,
      'role': 'assistant',
      'message': 'Here are some options.',
      'timestamp': '2026-10-23T10:00:00Z',
      'feedback': 'down',
      'truncated': true,
      'actions': [
        {'type': 'teleport', 'label': 'Beam me up'},
        {'type': 'course', 'label': 'Open Budgeting basics', 'slug': 'budgeting-basics'},
        {'type': 'course', 'label': 'No slug'},
        {'type': 'article', 'label': 'Read: Spotting a fake job offer', 'id': 2},
        {'type': 'place', 'id': 4},
        {'type': 'learn', 'label': 'Browse courses', 'query': 'budget'},
      ],
    });

    expect(m.feedback, ChatFeedback.down);
    expect(m.truncated, isTrue);
    expect(m.actions.map((a) => a.type), [ChatActionType.course, ChatActionType.article, ChatActionType.place]);
    expect(m.actions[0].slug, 'budgeting-basics');
    expect(m.actions[1].id, 2);
    expect(m.actions[2].label, 'See place');
  });

  test('parses every action type the contract names', () {
    final types = ['sos', 'fake_call', 'trusted_contacts', 'siren', 'learn', 'places'];
    final actions = types.map((t) => ChatAction.fromJson({'type': t, 'label': 'Go', 'query': 'salon'})).toList();

    expect(actions.map((a) => a?.type), [
      ChatActionType.sos,
      ChatActionType.fakeCall,
      ChatActionType.trustedContacts,
      ChatActionType.siren,
      ChatActionType.learn,
      ChatActionType.places,
    ]);
    expect(actions.last?.query, 'salon');
  });

  test('withFeedback keeps everything else', () {
    final m = ChatMessage(
      id: 1,
      role: ChatRole.assistant,
      text: 'A',
      timestamp: DateTime(2026, 10, 23),
      actions: const [ChatAction(type: ChatActionType.siren, label: 'Open the siren')],
    );

    final rated = m.withFeedback(ChatFeedback.up);
    expect(rated.feedback, ChatFeedback.up);
    expect(rated.id, 1);
    expect(rated.actions, hasLength(1));
    expect(rated.withFeedback(null).feedback, isNull);
  });
}
