import 'dart:async';

import 'package:Empuan/app/main_shell.dart' show AppTab;
import 'package:Empuan/data/api.dart';
import 'package:Empuan/features/ai/ai_chat_screen.dart';
import 'package:Empuan/models/chat_message.dart';
import 'package:Empuan/services/chatbot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Hands each answer to the test through [answer], so events can be pushed
/// one at a time.
class _FakeChatbot extends ChatbotService {
  _FakeChatbot() : super(client: MockClient((_) async => http.Response('{}', 500)));

  StreamController<ChatStreamEvent> answer = StreamController<ChatStreamEvent>();
  final sent = <(String, String?)>[];
  final regenerated = <(String, String?)>[];
  final ratings = <(int, ChatFeedback?, String?)>[];
  bool failFeedback = false;

  Stream<ChatStreamEvent> _next() {
    unawaited(answer.close());
    answer = StreamController<ChatStreamEvent>();
    return answer.stream;
  }

  @override
  Stream<ChatStreamEvent> stream({required String message, String? sessionId, bool useHistory = true}) {
    sent.add((message, sessionId));
    return _next();
  }

  @override
  Stream<ChatStreamEvent> regenerate(String sessionId, {String? question}) {
    regenerated.add((sessionId, question));
    return _next();
  }

  @override
  Future<ChatFeedback?> sendFeedback(int messageId, ChatFeedback? rating, {String? reason}) async {
    ratings.add((messageId, rating, reason));
    if (failFeedback) throw const ApiException('You’re offline.');
    return rating;
  }
}

ChatMessage _saved(int id, ChatRole role, String text, {List<ChatAction> actions = const [], bool truncated = false}) =>
    ChatMessage(id: id, role: role, text: text, timestamp: DateTime(2026, 10, 23), actions: actions, truncated: truncated);

Finder _answerText(String text) => find.textContaining(text, findRichText: true);

void main() {
  late _FakeChatbot service;
  late List<AppTab> tabs;

  setUp(() {
    service = _FakeChatbot();
    tabs = [];
  });
  tearDown(() => service.answer.close());

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: AiChatScreen(service: service, goToTab: tabs.add),
    ));
    await tester.pump();
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
  }

  /// Lets the throttled redraw and any entrance animations run.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> answerWith(WidgetTester tester, ChatMessage answer, {String question = 'Hi'}) async {
    service.answer
      ..add(const ChatMetaEvent('abc'))
      ..add(ChatDeltaEvent(answer.text))
      ..add(ChatDoneEvent(userMessage: _saved(1, ChatRole.user, question), assistantMessage: answer));
    await settle(tester);
  }

  testWidgets('streams the answer, then shows shortcuts and feedback', (tester) async {
    await pump(tester);
    await ask(tester, 'How do I budget?');

    expect(service.sent, [('How do I budget?', null)]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('Empuan AI is writing an answer'), findsOneWidget);

    service.answer
      ..add(const ChatMetaEvent('abc'))
      ..add(const ChatStatusEvent(tool: 'search_courses', label: 'Looking for courses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Looking for courses'), findsOneWidget);

    service.answer.add(const ChatDeltaEvent('Start with '));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_answerText('Start with'), findsWidgets);
    expect(find.text('Looking for courses'), findsNothing);

    service.answer.add(const ChatDeltaEvent('a simple budget.'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_answerText('Start with a simple budget.'), findsWidgets);
    expect(find.byTooltip('Helpful'), findsNothing);

    service.answer.add(ChatDoneEvent(
      userMessage: _saved(811, ChatRole.user, 'How do I budget?'),
      assistantMessage: _saved(812, ChatRole.assistant, 'Start with a simple budget.', actions: const [
        ChatAction(type: ChatActionType.course, label: 'Open Budgeting basics', slug: 'budgeting-basics'),
        ChatAction(type: ChatActionType.sos, label: 'How SOS works'),
      ]),
      title: 'Budgeting help',
    ));
    await settle(tester);

    expect(find.text('Budgeting help'), findsOneWidget);
    expect(find.text('Open Budgeting basics'), findsOneWidget);
    expect(find.text('How SOS works'), findsOneWidget);
    expect(find.byTooltip('Helpful'), findsOneWidget);
    expect(find.byTooltip('Not helpful'), findsOneWidget);

    await tester.tap(find.byTooltip('Helpful'));
    await settle(tester);
    expect(service.ratings, [(812, ChatFeedback.up, null)]);
    expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

    // SOS only switches to the Safety tab.
    await tester.tap(find.text('How SOS works'));
    await tester.pump();
    expect(tabs, [AppTab.safety]);
  });

  testWidgets('the saved text replaces what was streamed', (tester) async {
    await pump(tester);
    await ask(tester, 'Which crypto should I buy?');

    service.answer.add(const ChatDeltaEvent('Sure, the best coin is'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_answerText('the best coin'), findsWidgets);

    service.answer.add(ChatDoneEvent(
      assistantMessage: _saved(2, ChatRole.assistant, 'I can help with safety, work, money and wellbeing.'),
      blockedScope: true,
    ));
    await settle(tester);

    expect(_answerText('the best coin'), findsNothing);
    expect(_answerText('I can help with safety'), findsWidgets);
  });

  testWidgets('thumbs down asks why and rolls back when saving fails', (tester) async {
    await pump(tester);
    await ask(tester, 'Hi');
    await answerWith(tester, _saved(812, ChatRole.assistant, 'Hello!'));
    service.failFeedback = true;

    await tester.tap(find.byTooltip('Not helpful'));
    await settle(tester);
    expect(find.text('What went wrong?'), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_alt_rounded), findsOneWidget);

    await tester.tap(find.text('Not accurate'));
    await tester.pump();
    await tester.tap(find.text('Send feedback'));
    await settle(tester);

    expect(service.ratings, [(812, ChatFeedback.down, 'Not accurate')]);
    expect(find.byIcon(Icons.thumb_down_alt_rounded), findsNothing);
    expect(find.text('Couldn’t save your feedback. You’re offline.'), findsOneWidget);
  });

  testWidgets('rate limit says when to try again and pauses Send', (tester) async {
    await pump(tester);
    await ask(tester, 'Hi');

    service.answer.add(const ChatErrorEvent(
      ApiException('Too many messages.', statusCode: 429, code: 'rate_limited', retryAfter: Duration(seconds: 40)),
    ));
    await settle(tester);

    expect(find.text('You’ve sent a lot of messages. Try again in 40 seconds.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Hello?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(service.sent, hasLength(1));

    await tester.pump(const Duration(seconds: 41));
    await tester.tap(find.text('Retry'));
    await tester.pump();

    // Same question again, no duplicate bubble.
    expect(service.sent, [('Hi', null), ('Hi', null)]);
    expect(find.bySemanticsLabel('You: Hi'), findsOneWidget);
    await answerWith(tester, _saved(2, ChatRole.assistant, 'Hello!'));
    expect(find.bySemanticsLabel('You: Hi'), findsOneWidget);
  });

  testWidgets('a blocked answer has no Retry', (tester) async {
    await pump(tester);
    await ask(tester, 'Hi');

    service.answer.add(const ChatErrorEvent(ApiException('Blocked.', statusCode: 422, code: 'blocked', retryable: false)));
    await settle(tester);

    expect(find.text('Empuan AI can’t answer this one. Try asking in a different way.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a failed regenerate keeps the old answer', (tester) async {
    await pump(tester);
    await ask(tester, 'Hi');
    await answerWith(tester, _saved(2, ChatRole.assistant, 'First answer'));

    await tester.tap(find.byTooltip('Regenerate answer'));
    await tester.pump();
    expect(service.regenerated, [('abc', 'Hi')]);
    expect(_answerText('First answer'), findsNothing);

    service.answer.add(const ChatErrorEvent(ApiException('The AI is busy.', code: 'ai_unavailable')));
    await settle(tester);

    expect(_answerText('First answer'), findsWidgets);
    expect(find.text('Couldn’t get a new answer. The AI is busy.'), findsOneWidget);
    expect(service.sent, hasLength(1));
  });

  testWidgets('a cut-short answer offers Continue', (tester) async {
    await pump(tester);
    await ask(tester, 'Tell me everything');
    await answerWith(tester, _saved(2, ChatRole.assistant, 'Part one', truncated: true), question: 'Tell me everything');

    expect(find.text('Answer was cut short'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(service.sent.last, ('Please continue.', 'abc'));
  });

  testWidgets('with reduced motion the status label still shows and changes', (tester) async {
    await pump(tester, reduceMotion: true);
    await ask(tester, 'Find a salon');

    service.answer.add(const ChatStatusEvent(tool: 'find_places', label: 'Looking for places'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Looking for places'), findsOneWidget);

    service.answer.add(const ChatStatusEvent(tool: 'get_help_lines', label: 'Checking help lines'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Checking help lines'), findsOneWidget);
    expect(find.text('Looking for places'), findsNothing);
  });
}
