import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app/main_shell.dart' show AppTab, ShellScope;
import '../../components/chat_markdown_message.dart';
import '../../components/send_button.dart';
import '../../data/api.dart';
import '../../data/community_repository.dart' show ReportTarget;
import '../../data/content_repository.dart';
import '../../data/offline.dart';
import '../../models/chat_message.dart';
import '../../services/chatbot_service.dart';
import '../../ui/em_ui.dart';
import '../learn/article_screen.dart';
import '../learning/screens/learning_catalog_screen.dart';
import '../learning/screens/learning_course_detail_screen.dart';
import '../moderation/report_sheet.dart';
import '../places/place_screen.dart';
import '../places/places_screen.dart';
import '../safety/fake_call_screen.dart';
import '../safety/help_lines.dart';
import '../safety/siren_screen.dart';
import '../safety/trusted_contacts_screen.dart';
import 'ai_history_screen.dart';

/// Opens Empuan AI. With [sessionId] it continues a past chat; with [prompt]
/// it sends that message straight away.
Future<void> openEmpuanAi(BuildContext context, {String? sessionId, String? prompt}) {
  // The chat sits above the tab shell, so take its tab switcher along.
  final goToTab = ShellScope.maybeOf(context)?.goTo;
  return pushScreen<void>(context, AiChatScreen(sessionId: sessionId, initialPrompt: prompt, goToTab: goToTab));
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.sessionId, this.initialPrompt, this.goToTab, this.service});

  @visibleForTesting
  final ChatbotService? service;

  final String? sessionId;
  final String? initialPrompt;

  /// Switches the main tab, for the SOS shortcut.
  final void Function(AppTab tab)? goToTab;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _maxLength = 2000;

  /// How often the growing answer is redrawn: about 30 times a second.
  static const _frame = Duration(milliseconds: 33);

  /// Within this distance of the newest message the list follows the answer.
  static const _nearBottom = 80.0;

  late final _service = widget.service ?? ChatbotService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String? _sessionId;

  /// True once the server has saved messages in [_sessionId]. A session id
  /// from a failed first answer is dropped, since nothing was saved.
  bool _sessionSaved = false;
  String? _serverTitle;
  List<ChatMessage> _messages = [];

  bool _loadingHistory = false;
  String? _historyError;

  /// The answer being written. Its text is buffered and pushed to
  /// [_liveText] at most once per [_frame], so only that bubble redraws.
  StreamSubscription<ChatStreamEvent>? _answer;
  Key? _liveKey;
  final _buffer = StringBuffer();
  final _liveText = ValueNotifier<String>('');
  final _liveStatus = ValueNotifier<String?>(null);
  Timer? _flushTimer;

  ApiException? _sendError;
  String _errorLead = 'No answer.';
  VoidCallback? _retryAction;

  /// Set after `rate_limited`; Send stays off until then.
  DateTime? _pausedUntil;
  Timer? _pauseTimer;

  /// Ignores history that arrives after the user switched to another chat.
  int _generation = 0;

  /// Messages added in this visit that should animate in on their first build.
  final Set<ChatMessage> _fresh = {};

  /// Answers that just finished, whose shortcuts should stagger in.
  final Set<ChatMessage> _justDone = {};

  /// Assistant messages with a rating request in flight.
  final Set<int> _rating = {};
  ChatAction? _openingAction;

  /// List keys, so a message keeps its place when the server copy replaces
  /// the local one.
  final _keys = Expando<Key>();

  bool get _sending => _answer != null;

  bool get _paused => _pausedUntil != null;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _sessionId = widget.sessionId;
    _sessionSaved = _sessionId != null;
    _start();
  }

  Future<void> _start() async {
    if (_sessionId != null) await _loadHistory();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty && mounted && _historyError == null) _send(prompt);
  }

  @override
  void dispose() {
    unawaited(_answer?.cancel());
    _flushTimer?.cancel();
    _pauseTimer?.cancel();
    _liveText.dispose();
    _liveStatus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _title {
    final server = _serverTitle?.trim();
    if (server != null && server.isNotEmpty) return server;
    final first = _messages.where((m) => m.isUser).firstOrNull?.text.trim();
    if (first == null || first.isEmpty) return 'Empuan AI';
    final line = first.split('\n').first;
    return line.length > 40 ? '${line.substring(0, 40).trimRight()}…' : line;
  }

  Key _keyOf(ChatMessage m) => _keys[m] ??= ObjectKey(m);

  Future<void> _loadHistory() async {
    final id = _sessionId;
    if (id == null) return;
    final generation = _generation;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _service.getHistory(id);
      if (!mounted || generation != _generation) return;
      setState(() => _messages = history);
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _historyError = e.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _loadingHistory = false);
    }
  }

  /// Sends [text]. When [resend] is true the question is already the last
  /// message, as with Retry. The server saved nothing for a failed answer,
  /// so sending again never duplicates.
  void _send(String text, {bool resend = false}) {
    if (_sending || _paused || text.trim().isEmpty) return;
    final question = resend ? _messages.last : _markFresh(ChatMessage.user(text));
    if (!resend) setState(() => _messages = [..._messages, question]);
    _scrollToEnd();
    _listen(
      _service.stream(message: text, sessionId: _sessionId),
      question: question,
      lead: 'No answer.',
      retry: () => _send(question.text, resend: true),
    );
  }

  /// Streams a new answer to the last question. The old answer comes back
  /// if that fails, because the server only swaps it on success.
  void _regenerate() {
    final id = _sessionId;
    if (_sending || _paused || id == null || _messages.length < 2) return;
    final answer = _messages.last;
    final question = _messages[_messages.length - 2];
    if (answer.isUser || !question.isUser) return;
    setState(() => _messages = _messages.sublist(0, _messages.length - 1));
    _listen(
      _service.regenerate(id, question: question.text),
      question: question,
      replacing: answer,
      lead: 'Couldn’t get a new answer.',
      retry: _regenerate,
    );
  }

  void _listen(
    Stream<ChatStreamEvent> events, {
    required ChatMessage question,
    required String lead,
    required VoidCallback retry,
    ChatMessage? replacing,
  }) {
    _flushTimer?.cancel();
    _flushTimer = null;
    _buffer.clear();
    _liveText.value = '';
    _liveStatus.value = null;
    late final StreamSubscription<ChatStreamEvent> subscription;
    // The service always ends with done or error; this covers anything else.
    void ended() {
      if (mounted && identical(_answer, subscription)) {
        _fail(const ApiException('The answer stopped unexpectedly. Please try again.'),
            replacing: replacing, lead: lead, retry: retry);
      }
    }

    setState(() {
      _sendError = null;
      _liveKey = UniqueKey();
      _answer = subscription = events.listen(
        (event) {
          if (!mounted) return;
          switch (event) {
            case ChatMetaEvent(:final sessionId):
              _sessionId = sessionId;
            case ChatStatusEvent(:final label):
              if (_buffer.isEmpty && label.isNotEmpty) _liveStatus.value = label;
            case ChatDeltaEvent(:final text):
              _buffer.write(text);
              _flushTimer ??= Timer(_frame, _flush);
            case ChatDoneEvent():
              _finish(event, question);
            case ChatErrorEvent(:final error):
              _fail(error, replacing: replacing, lead: lead, retry: retry);
          }
        },
        onError: (Object _) => ended(),
        onDone: ended,
      );
    });
  }

  void _flush() {
    _flushTimer = null;
    _liveText.value = _buffer.toString();
    _liveStatus.value = null;
  }

  void _finish(ChatDoneEvent done, ChatMessage question) {
    _flushTimer?.cancel();
    _flushTimer = null;
    final user = done.userMessage ?? question;
    // The server text wins over what was streamed, e.g. for a refusal.
    final answer = done.assistantMessage;
    _keys[user] = _keyOf(question);
    _keys[answer] = _liveKey;
    _justDone.add(answer);
    WidgetsBinding.instance.addPostFrameCallback((_) => _justDone.remove(answer));
    setState(() {
      final i = _messages.lastIndexOf(question);
      final before = i < 0 ? _messages : _messages.sublist(0, i);
      _messages = [...before, user, answer];
      _answer = null;
      _liveKey = null;
      _sessionSaved = true;
      if (done.title != null) _serverTitle = done.title;
    });
  }

  void _fail(ApiException error, {ChatMessage? replacing, required String lead, required VoidCallback retry}) {
    _flushTimer?.cancel();
    _flushTimer = null;
    setState(() {
      _answer = null;
      _liveKey = null;
      if (replacing != null) _messages = [..._messages, replacing];
      if (!_sessionSaved) _sessionId = null;
      _sendError = error;
      _errorLead = lead;
      _retryAction = retry;
    });
    final wait = error.retryAfter;
    if (error.code == 'rate_limited' && wait != null && wait > Duration.zero) _pauseFor(wait);
  }

  void _pauseFor(Duration wait) {
    _pauseTimer?.cancel();
    setState(() => _pausedUntil = DateTime.now().add(wait));
    _pauseTimer = Timer(wait, () {
      if (mounted) setState(() => _pausedUntil = null);
    });
  }

  ChatMessage _markFresh(ChatMessage m) {
    _fresh.add(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fresh.remove(m));
    return m;
  }

  void _submit() {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _paused) return;
    _input.clear();
    _send(text);
  }

  void _stopAnswer() {
    unawaited(_answer?.cancel());
    _answer = null;
    _liveKey = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _newChat() {
    setState(() {
      _stopAnswer();
      _generation++;
      _sessionId = null;
      _sessionSaved = false;
      _serverTitle = null;
      _messages = [];
      _sendError = null;
      _historyError = null;
      _loadingHistory = false;
    });
    _input.clear();
  }

  void _openSession(String id, {String? title}) {
    if (id == _sessionId && _historyError == null) return;
    setState(() {
      _stopAnswer();
      _generation++;
      _sessionId = id;
      _sessionSaved = true;
      _serverTitle = title;
      _messages = [];
      _sendError = null;
    });
    _loadHistory();
  }

  Future<void> _openHistory() async {
    final result = await Navigator.of(context).push<AiHistoryResult>(
      MaterialPageRoute(
        builder: (_) => AiHistoryScreen(
          service: widget.service,
          onDeleted: (id) {
            if (id == _sessionId) _newChat();
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    final id = result.sessionId;
    if (id == null) {
      _newChat();
    } else {
      _openSession(id, title: result.title);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (EmMotion.reduced(context)) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(0, duration: EmMotion.slow, curve: EmMotion.enter);
      }
    });
  }

  /// The newest message grew by [dy]. The list is reversed, so growth pushes
  /// older messages up: near the bottom that is what we want (the list
  /// follows the answer); further up, scroll by the same amount so the text
  /// being read stays put.
  void _onNewestResized(double dy) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final p = _scroll.position;
      if (p.isScrollingNotifier.value) return;
      if (p.pixels <= _nearBottom) {
        if (p.pixels > 0) _scroll.jumpTo(0);
      } else {
        _scroll.jumpTo((p.pixels + dy).clamp(p.minScrollExtent, p.maxScrollExtent));
      }
    });
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showEmToast(context, 'Answer copied');
  }

  void _report(ChatMessage m, int index) {
    // Saved answers are reported by id; older ones by their place in the chat.
    final id = m.id;
    showReportSheet(context, target: ReportTarget.aiAnswer, targetId: '$_sessionId:${id ?? index}');
  }

  /// Optimistic: the thumb changes at once and goes back if saving fails.
  Future<void> _rate(ChatMessage m, ChatFeedback tapped) async {
    final id = m.id;
    if (id == null || _rating.contains(id)) return;
    final next = m.feedback == tapped ? null : tapped;
    _rating.add(id);
    _replaceById(id, (current) => current.withFeedback(next));
    try {
      String? reason;
      if (next == ChatFeedback.down) {
        reason = await _askWhatWentWrong(context);
        if (!mounted) return;
      }
      await _service.sendFeedback(id, next, reason: reason);
      if (mounted && next == ChatFeedback.down) showEmToast(context, 'Thanks for your feedback', icon: Icons.check_rounded);
    } on ApiException catch (e) {
      if (!mounted) return;
      _replaceById(id, (current) => current.withFeedback(m.feedback));
      showEmToast(context, 'Couldn’t save your feedback. ${e.message}');
    } finally {
      _rating.remove(id);
    }
  }

  void _replaceById(int id, ChatMessage Function(ChatMessage current) change) {
    final i = _messages.indexWhere((x) => x.id == id && !x.isUser);
    if (i < 0) return;
    final old = _messages[i];
    final updated = change(old);
    _keys[updated] = _keyOf(old);
    setState(() => _messages = [..._messages]..[i] = updated);
  }

  Future<void> _runAction(ChatAction action) async {
    switch (action.type) {
      case ChatActionType.sos:
        // Only shows the SOS setup. Nothing is ever sent from here.
        final goTo = widget.goToTab ?? ShellScope.maybeOf(context)?.goTo;
        await Navigator.of(context).maybePop();
        goTo?.call(AppTab.safety);
      case ChatActionType.fakeCall:
        await pushScreen<void>(context, const FakeCallScreen());
      case ChatActionType.trustedContacts:
        await pushScreen<void>(context, const TrustedContactsScreen());
      case ChatActionType.siren:
        await pushScreen<void>(context, const SirenScreen());
      case ChatActionType.places:
        await pushScreen<void>(context, const PlacesScreen());
      case ChatActionType.learn:
        await pushScreen<void>(context, LearningCatalogScreen(initialQuery: action.query));
      case ChatActionType.course:
        await pushScreen<void>(context, LearningCourseDetailScreen(slug: action.slug!));
      case ChatActionType.article:
        final article = await _fetchFor(action, () => ArticlesRepository().article(action.id!), 'this article');
        if (article != null && mounted) await pushScreen<void>(context, ArticleScreen(article: article));
      case ChatActionType.place:
        final place = await _fetchFor(action, () => PlacesRepository().place(action.id!), 'this place');
        if (place != null && mounted) await pushScreen<void>(context, PlaceScreen(place: place));
    }
  }

  /// Loads what a shortcut points to, with a spinner on its chip.
  Future<T?> _fetchFor<T>(ChatAction action, Future<T> Function() load, String what) async {
    if (_openingAction != null) return null;
    setState(() => _openingAction = action);
    try {
      return await load();
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, 'Couldn’t open $what. ${e.message}');
      return null;
    } finally {
      if (mounted) setState(() => _openingAction = null);
    }
  }

  // Empuan AI needs the server, so offline it says so and offers the help
  // lines, which work over the phone network.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: OfflineStatus.instance, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final offline = OfflineStatus.instance.offline;
    final empty = _messages.isEmpty && !_sending && !_loadingHistory && _historyError == null;
    return Scaffold(
      appBar: EmTopBar(
        title: _title,
        actions: [
          EmIconButton(icon: Icons.history_rounded, label: 'Past chats', onPressed: _openHistory),
          if (!empty) EmIconButton(icon: Icons.edit_square, label: 'New chat', onPressed: _newChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: EmStateSwitcher(
              stateKey: _loadingHistory
                  ? 'loading'
                  : _historyError != null
                      ? 'error'
                      : empty
                          ? 'new'
                          : offline && empty
                              ? 'offline'
                              : 'chat-$_generation',
              child: offline && empty ? const _OfflineChat() : _body(empty),
            ),
          ),
          _disclaimer(empty && !offline),
          _InputBar(
            controller: _input,
            hint: offline ? 'You’re offline' : (empty ? 'Message Empuan AI' : 'Ask a follow-up'),
            sending: _sending,
            enabled: !offline && !_loadingHistory && _historyError == null,
            paused: _paused,
            maxLength: _maxLength,
            onSend: _submit,
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(bool visible) {
    final child = visible
        ? const Padding(
            padding: EdgeInsets.fromLTRB(28, 0, 28, 8),
            child: Text(
              'AI answers can be wrong. They’re general information, not legal or financial advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.textSecondary),
            ),
          )
        : const SizedBox(width: double.infinity);
    // AnimatedSize can't run with a zero duration, so skip it entirely.
    if (EmMotion.reduced(context)) return child;
    return AnimatedSize(duration: EmMotion.medium, curve: EmMotion.enter, child: child);
  }

  String _errorText(ApiException e) {
    final wait = e.retryAfter;
    return switch (e.code) {
      'rate_limited' => wait == null
          ? 'You’ve sent a lot of messages. Wait a moment, then try again.'
          : 'You’ve sent a lot of messages. Try again in ${_waitText(wait)}.',
      'blocked' => 'Empuan AI can’t answer this one. Try asking in a different way.',
      'ai_timeout' => '$_errorLead Empuan AI took too long to answer. Please try again.',
      _ => '$_errorLead ${e.message}',
    };
  }

  Widget _body(bool empty) {
    if (_loadingHistory) return const _ChatSkeleton();
    if (_historyError != null) {
      return Center(child: EmStateView.error(message: _historyError!, onRetry: _loadHistory));
    }
    if (empty) return _NewChat(onSuggestion: _send);

    final lastAnswer = _messages.lastIndexWhere((m) => !m.isUser);
    final last = _messages.length - 1;
    final error = _sendError;
    final items = <(Key, Widget)>[
      for (var i = 0; i < _messages.length; i++)
        (
          _keyOf(_messages[i]),
          _animatedIn(
            _messages[i].isUser,
            _fresh.contains(_messages[i]),
            _messages[i].isUser ? _UserBubble(text: _messages[i].text) : _answerFor(_messages[i], i, i == lastAnswer && i == last),
          ),
        ),
      if (_liveKey != null)
        (_liveKey!, _animatedIn(false, true, _LiveAnswer(text: _liveText, status: _liveStatus))),
      if (error != null && !_sending)
        (
          const ValueKey('error'),
          EmFadeSlideIn(
            duration: EmMotion.medium,
            child: _SendError(
              message: _errorText(error),
              onRetry: error.retryable && !_paused ? _retryAction : null,
            ),
          ),
        ),
    ];
    // Reversed so the newest message stays pinned above the input bar.
    final reversed = items.reversed.toList();
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: reversed.length,
      findChildIndexCallback: (key) {
        final i = reversed.indexWhere((e) => e.$1 == key);
        return i < 0 ? null : i;
      },
      itemBuilder: (_, i) => KeyedSubtree(
        key: reversed[i].$1,
        child: _SizeWatcher(
          onResize: i == 0 ? _onNewestResized : null,
          child: Padding(padding: const EdgeInsets.only(top: 16), child: reversed[i].$2),
        ),
      ),
    );
  }

  Widget _answerFor(ChatMessage m, int index, bool isLatest) {
    final idle = !_sending && !_paused;
    return _AiAnswer(
      message: m,
      announce: index == _messages.length - 1,
      animateActions: _justDone.contains(m),
      openingAction: _openingAction,
      onCopy: () => _copy(m.text),
      onRegenerate: isLatest && idle ? _regenerate : null,
      onReport: () => _report(m, index),
      onRate: m.id == null ? null : (rating) => _rate(m, rating),
      onAction: _runAction,
      onContinue: isLatest && m.truncated && idle ? () => _send('Please continue.') : null,
    );
  }

  /// New messages slide in from their own side; loaded ones just appear.
  Widget _animatedIn(bool isUser, bool fresh, Widget child) {
    return EmFadeSlideIn(
      offset: Offset(isUser ? 24 : -24, 0),
      duration: fresh ? EmMotion.slow : Duration.zero,
      child: child,
    );
  }
}

/// "40 seconds", "5 minutes", "2 hours".
String _waitText(Duration wait) {
  String plural(int n, String unit) => '$n ${n == 1 ? unit : '${unit}s'}';
  final seconds = wait.inSeconds;
  if (seconds < 60) return plural(math.max(seconds, 1), 'second');
  if (seconds < 3600) return plural((seconds / 60).ceil(), 'minute');
  return plural((seconds / 3600).ceil(), 'hour');
}

/// Reports changes to its child's height after layout.
class _SizeWatcher extends SingleChildRenderObjectWidget {
  const _SizeWatcher({required this.onResize, super.child});

  final ValueChanged<double>? onResize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeWatcher(onResize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeWatcher renderObject) => renderObject.onResize = onResize;
}

class _RenderSizeWatcher extends RenderProxyBox {
  _RenderSizeWatcher(this.onResize);

  ValueChanged<double>? onResize;
  double? _height;

  @override
  void performLayout() {
    super.performLayout();
    final previous = _height;
    _height = size.height;
    if (previous != null && previous != size.height) onResize?.call(size.height - previous);
  }
}

/// Placeholder while a past chat loads.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading chat',
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(alignment: Alignment.centerRight, child: EmSkeleton(width: 220, height: 44, radius: 18)),
            SizedBox(height: 20),
            EmSkeleton(width: 110, height: 14),
            SizedBox(height: 12),
            EmSkeleton(height: 14),
            SizedBox(height: 8),
            EmSkeleton(height: 14),
            SizedBox(height: 8),
            EmSkeleton(height: 14, width: 200),
            SizedBox(height: 24),
            Align(alignment: Alignment.centerRight, child: EmSkeleton(width: 180, height: 44, radius: 18)),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the suggestions while offline.
class _OfflineChat extends StatelessWidget {
  const _OfflineChat();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        EmFadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmIconTile(Icons.wifi_off_rounded, size: 48),
              const SizedBox(height: 16),
              Semantics(header: true, child: Text('Empuan AI needs internet', style: theme.headlineMedium)),
              const SizedBox(height: 8),
              Text(
                'Connect to Wi-Fi or mobile data to ask a question. Your past chats will be here when you’re back online.',
                style: theme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const EmFadeSlideIn(index: 1, child: EmSectionHeader('If you need help now')),
        const SizedBox(height: 12),
        const EmFadeSlideIn(index: 2, child: HelpLinesGroup()),
        const SizedBox(height: 8),
        EmFadeSlideIn(
          index: 3,
          child: Text('Calls use your phone network, not the internet. SOS works offline too.', style: theme.bodySmall),
        ),
      ],
    );
  }
}

class _NewChat extends StatelessWidget {
  const _NewChat({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _suggestions = [
    (Icons.person_outline_rounded, 'How do I tell a coworker to stop commenting on my looks?'),
    (Icons.shield_outlined, 'What can I do if I’m harassed on the KRL?'),
    (Icons.work_outline_rounded, 'How do I ask for a raise?'),
    (Icons.payments_outlined, 'Is this online loan offer safe?'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        EmFadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmIconTile(Icons.auto_awesome_rounded, tone: EmTileTone.primary, size: 48),
              const SizedBox(height: 16),
              Semantics(header: true, child: Text('What’s on your mind?', style: theme.headlineMedium)),
              const SizedBox(height: 8),
              Text(
                'Ask about safety, work, money, relationships or digital skills. Write in English or Bahasa Indonesia.',
                style: theme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final (i, (icon, text)) in _suggestions.indexed) ...[
          EmFadeSlideIn(
            index: i + 2,
            child: EmCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              onTap: () => onSuggestion(text),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: SelectableText(
            text,
            semanticsLabel: 'You: $text',
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 22 / 15),
          ),
        ),
      ),
    );
  }
}

class _AiLabel extends StatelessWidget {
  const _AiLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        EmIconTile(Icons.auto_awesome_rounded, tone: EmTileTone.primary, size: 28),
        SizedBox(width: 8),
        Text('Empuan AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _AiAnswer extends StatelessWidget {
  const _AiAnswer({
    required this.message,
    required this.announce,
    required this.animateActions,
    required this.onCopy,
    required this.onReport,
    required this.onAction,
    this.openingAction,
    this.onRegenerate,
    this.onRate,
    this.onContinue,
  });

  final ChatMessage message;
  final bool announce;

  /// Stagger the shortcuts in: the answer has just finished.
  final bool animateActions;
  final VoidCallback onCopy;
  final VoidCallback onReport;
  final ValueChanged<ChatAction> onAction;
  final ChatAction? openingAction;
  final VoidCallback? onRegenerate;

  /// Null for answers the server hasn't saved (no id to rate).
  final ValueChanged<ChatFeedback>? onRate;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final feedback = message.feedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiLabel(),
        const SizedBox(height: 10),
        Semantics(liveRegion: announce, child: ChatMarkdownMessage(data: message.text)),
        if (message.truncated) ...[
          const SizedBox(height: 10),
          _CutShort(onContinue: onContinue),
        ],
        if (message.actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, action) in message.actions.indexed)
                EmFadeSlideIn(
                  index: i + 1,
                  offset: const Offset(0, 8),
                  duration: animateActions ? EmMotion.slow : Duration.zero,
                  child: _ActionChip(
                    action: action,
                    loading: identical(openingAction, action),
                    onTap: () => onAction(action),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Row(
            children: [
              EmIconButton(icon: Icons.copy_rounded, label: 'Copy answer', color: AppColors.textSecondary, onPressed: onCopy),
              if (onRate != null) ...[
                _FeedbackButton(
                  label: 'Helpful',
                  icon: Icons.thumb_up_alt_outlined,
                  selectedIcon: Icons.thumb_up_alt_rounded,
                  selected: feedback == ChatFeedback.up,
                  onPressed: () => onRate!(ChatFeedback.up),
                ),
                _FeedbackButton(
                  label: 'Not helpful',
                  icon: Icons.thumb_down_alt_outlined,
                  selectedIcon: Icons.thumb_down_alt_rounded,
                  selected: feedback == ChatFeedback.down,
                  onPressed: () => onRate!(ChatFeedback.down),
                ),
              ],
              if (onRegenerate != null)
                EmIconButton(
                    icon: Icons.refresh_rounded, label: 'Regenerate answer', color: AppColors.textSecondary, onPressed: onRegenerate),
              EmIconButton(icon: Icons.outlined_flag_rounded, label: 'Report answer', color: AppColors.textSecondary, onPressed: onReport),
            ],
          ),
        ),
      ],
    );
  }
}

/// The answer while it is being written: typing dots (with what the AI is
/// doing, if it says) until the first words arrive, then the growing text.
class _LiveAnswer extends StatelessWidget {
  const _LiveAnswer({required this.text, required this.status});

  final ValueListenable<String> text;
  final ValueListenable<String?> status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiLabel(),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: text,
          builder: (_, value, __) => value.isEmpty
              ? ValueListenableBuilder<String?>(
                  valueListenable: status,
                  builder: (_, label, __) => _TypingIndicator(status: label),
                )
              // Screen readers hear the whole answer once it's done.
              : ExcludeSemantics(child: ChatMarkdownMessage(data: value)),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({this.status});

  /// What the AI is doing, e.g. "Looking for courses".
  final String? status;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (EmMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return Semantics(
      container: true,
      liveRegion: true,
      label: status == null ? 'Empuan AI is writing an answer' : 'Empuan AI: $status',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 20,
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Transform.translate(
                        offset: Offset(0, -6 * _bounce(i)),
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6, bottom: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.45 + 0.55 * _bounce(i)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AnimatedSwitcher(
                  duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
                  switchInCurve: EmMotion.enter,
                  switchOutCurve: EmMotion.exit,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(
                    status ?? '',
                    key: ValueKey(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 0 at rest, 1 at the top of the hop. Each dot hops a third of a cycle
  /// after the previous one.
  double _bounce(int i) {
    if (!_controller.isAnimating) return 0.5;
    final t = (_controller.value - i * 0.18) % 1.0;
    if (t > 0.5) return 0;
    return math.sin(t * 2 * math.pi);
  }
}

/// A shortcut the AI suggested, e.g. "Start a fake call".
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.onTap, this.loading = false});

  final ChatAction action;
  final VoidCallback onTap;
  final bool loading;

  static IconData _icon(ChatActionType type) => switch (type) {
        ChatActionType.sos => Icons.sos_rounded,
        ChatActionType.fakeCall => Icons.phone_in_talk_rounded,
        ChatActionType.trustedContacts => Icons.people_alt_rounded,
        ChatActionType.siren => Icons.campaign_rounded,
        ChatActionType.course => Icons.school_rounded,
        ChatActionType.learn => Icons.school_outlined,
        ChatActionType.article => Icons.article_rounded,
        ChatActionType.place => Icons.place_rounded,
        ChatActionType.places => Icons.map_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: ExcludeSemantics(
        child: EmPressable(
          enabled: !loading,
          child: Material(
            color: AppColors.surface,
            shape: const StadiumBorder(side: BorderSide(color: AppColors.line2)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: loading ? null : onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: loading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Icon(_icon(action.type), size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumb that pops when it becomes selected.
class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(selected),
                tween: Tween(begin: selected && !EmMotion.reduced(context) ? 0.6 : 1, end: 1),
                duration: EmMotion.slow,
                curve: EmMotion.pop,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown under an answer that hit the length limit.
class _CutShort extends StatelessWidget {
  const _CutShort({this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text('Answer was cut short', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        if (onContinue != null) EmChip(label: 'Continue', selected: false, onTap: onContinue!),
      ],
    );
  }
}

class _SendError extends StatelessWidget {
  const _SendError({required this.message, this.onRetry});

  final String message;

  /// Null when trying again won't help yet.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 10, onRetry == null ? 14 : 8, 10),
        decoration: BoxDecoration(
          color: AppColors.dangerTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textPrimary),
              ),
            ),
            if (onRetry != null)
              EmButton(label: 'Retry', variant: EmButtonVariant.text, small: true, expand: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Asks why an answer wasn't helpful. Every field is optional; returns the
/// reason to send, or null when the user skipped.
Future<String?> _askWhatWentWrong(BuildContext context) {
  return showEmSheet<String>(context, builder: (_) => const _FeedbackForm());
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm();

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  static const _reasons = ['Not accurate', 'Not helpful', 'Unsafe or harmful', 'Something else'];

  final _details = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _send() {
    final parts = [_reason, _details.text.trim()].whereType<String>().where((p) => p.isNotEmpty);
    Navigator.of(context).pop(parts.join(': '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EmSheetHeader(
          title: 'What went wrong?',
          message: 'Optional. It helps us make Empuan AI better. To flag a harmful answer for review, use Report instead.',
        ),
        const SizedBox(height: 12),
        for (final r in _reasons) ...[
          EmOption(label: r, selected: _reason == r, onTap: () => setState(() => _reason = _reason == r ? null : r)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        EmTextField(label: 'Tell us more (optional)', controller: _details, maxLines: 3, maxLength: 400),
        const SizedBox(height: 16),
        EmButton(label: 'Send feedback', onPressed: _send),
        const SizedBox(height: 8),
        EmButton(label: 'Skip', variant: EmButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hint,
    required this.sending,
    required this.enabled,
    required this.maxLength,
    required this.onSend,
    this.paused = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool sending;
  final bool enabled;

  /// Send is off for a while after too many messages.
  final bool paused;
  final int maxLength;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && !sending && !paused && controller.text.trim().isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              readOnly: sending,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.line2)),
                enabledBorder:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.line2)),
                disabledBorder:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.line)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SendButton(label: 'Send', size: 48, enabled: canSend, sending: sending, onPressed: onSend),
        ],
      ),
    );
  }
}
