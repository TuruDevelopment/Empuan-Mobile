import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chat_markdown_message.dart';
import '../../components/send_button.dart';
import '../../data/api.dart';
import '../../data/community_repository.dart' show ReportTarget;
import '../../models/chat_message.dart';
import '../../services/chatbot_service.dart';
import '../../ui/em_ui.dart';
import '../moderation/report_sheet.dart';
import 'ai_history_screen.dart';

/// Opens Empuan AI. With [sessionId] it continues a past chat; with [prompt]
/// it sends that message straight away.
Future<void> openEmpuanAi(BuildContext context, {String? sessionId, String? prompt}) {
  return pushScreen<void>(context, AiChatScreen(sessionId: sessionId, initialPrompt: prompt));
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.sessionId, this.initialPrompt, this.service});

  @visibleForTesting
  final ChatbotService? service;

  final String? sessionId;
  final String? initialPrompt;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _maxLength = 2000;

  late final _service = widget.service ?? ChatbotService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String? _sessionId;
  List<ChatMessage> _messages = [];

  bool _loadingHistory = false;
  String? _historyError;

  bool _sending = false;
  String? _sendError;

  /// Ignores answers that arrive after the user switched to another chat.
  int _generation = 0;

  /// Messages added in this visit that should animate in on their first build.
  final Set<ChatMessage> _fresh = {};

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _sessionId = widget.sessionId;
    _start();
  }

  Future<void> _start() async {
    if (_sessionId != null) await _loadHistory();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty && mounted && _historyError == null) unawaited(_send(prompt));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _title {
    final first = _messages.where((m) => m.isUser).firstOrNull?.text.trim();
    if (first == null || first.isEmpty) return 'Empuan AI';
    final line = first.split('\n').first;
    return line.length > 40 ? '${line.substring(0, 40).trimRight()}…' : line;
  }

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

  /// Sends [text]. When [resend] is true the user message is already shown,
  /// as with Retry and Regenerate.
  Future<void> _send(String text, {bool resend = false}) async {
    if (_sending || text.trim().isEmpty) return;
    final generation = _generation;
    setState(() {
      if (!resend) _messages = [..._messages, _markFresh(ChatMessage.user(text))];
      _sending = true;
      _sendError = null;
    });
    _scrollToEnd();
    try {
      // A session is only created once there is something to save in it.
      var id = _sessionId;
      if (id == null) {
        id = await _service.createNewSession();
        if (!mounted || generation != _generation) return;
        _sessionId = id;
      }
      final answer = await _service.sendMessage(message: text, sessionId: id);
      if (!mounted || generation != _generation) return;
      setState(() => _messages = [..._messages, _markFresh(ChatMessage.assistant(answer))]);
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _sendError = e.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  ChatMessage _markFresh(ChatMessage m) {
    _fresh.add(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fresh.remove(m));
    return m;
  }

  void _submit() {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    _send(text);
  }

  void _retry() {
    final last = _messages.lastOrNull;
    if (last != null && last.isUser) _send(last.text, resend: true);
  }

  void _regenerate() {
    if (_sending || _messages.length < 2) return;
    final question = _messages[_messages.length - 2];
    if (!question.isUser) return;
    setState(() => _messages = _messages.sublist(0, _messages.length - 1));
    _send(question.text, resend: true);
  }

  void _newChat() {
    setState(() {
      _generation++;
      _sessionId = null;
      _messages = [];
      _sending = false;
      _sendError = null;
      _historyError = null;
      _loadingHistory = false;
    });
    _input.clear();
  }

  void _openSession(String id) {
    if (id == _sessionId && _historyError == null) return;
    setState(() {
      _generation++;
      _sessionId = id;
      _messages = [];
      _sending = false;
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
      _openSession(id);
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

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showEmToast(context, 'Answer copied');
  }

  void _report(int index) {
    showReportSheet(context, target: ReportTarget.aiAnswer, targetId: '$_sessionId:$index');
  }

  @override
  Widget build(BuildContext context) {
    final empty = _messages.isEmpty && !_loadingHistory && _historyError == null;
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
                          : 'chat-$_generation',
              child: _body(empty),
            ),
          ),
          _disclaimer(empty),
          _InputBar(
            controller: _input,
            hint: empty ? 'Message Empuan AI' : 'Ask a follow-up',
            sending: _sending,
            enabled: !_loadingHistory && _historyError == null,
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

  Widget _body(bool empty) {
    if (_loadingHistory) return const _ChatSkeleton();
    if (_historyError != null) {
      return Center(child: EmStateView.error(message: _historyError!, onRetry: _loadHistory));
    }
    if (empty) return _NewChat(onSuggestion: _send);

    final lastAnswer = _messages.lastIndexWhere((m) => !m.isUser);
    final items = <(Key, Widget)>[
      for (var i = 0; i < _messages.length; i++)
        (
          ObjectKey(_messages[i]),
          _animatedIn(
            _messages[i],
            _messages[i].isUser
                ? _UserBubble(text: _messages[i].text)
                : _AiAnswer(
                    text: _messages[i].text,
                    announce: i == _messages.length - 1,
                    onCopy: () => _copy(_messages[i].text),
                    onRegenerate: i == lastAnswer && i == _messages.length - 1 && !_sending ? _regenerate : null,
                    onReport: () => _report(i),
                  ),
          ),
        ),
      if (_sending)
        (const ValueKey('typing'), const EmFadeSlideIn(offset: Offset(-24, 0), duration: EmMotion.medium, child: _TypingIndicator())),
      if (_sendError != null && !_sending)
        (const ValueKey('error'), EmFadeSlideIn(duration: EmMotion.medium, child: _SendError(message: _sendError!, onRetry: _retry))),
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
        child: Padding(padding: const EdgeInsets.only(top: 16), child: reversed[i].$2),
      ),
    );
  }

  /// New messages slide in from their own side; loaded ones just appear.
  Widget _animatedIn(ChatMessage m, Widget child) {
    return EmFadeSlideIn(
      offset: Offset(m.isUser ? 24 : -24, 0),
      duration: _fresh.contains(m) ? EmMotion.slow : Duration.zero,
      child: child,
    );
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
    required this.text,
    required this.announce,
    required this.onCopy,
    required this.onReport,
    this.onRegenerate,
  });

  final String text;
  final bool announce;
  final VoidCallback onCopy;
  final VoidCallback onReport;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiLabel(),
        const SizedBox(height: 10),
        Semantics(liveRegion: announce, child: ChatMarkdownMessage(data: text)),
        const SizedBox(height: 4),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Row(
            children: [
              EmIconButton(icon: Icons.copy_rounded, label: 'Copy answer', color: AppColors.textSecondary, onPressed: onCopy),
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
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
    return Semantics(
      liveRegion: true,
      label: 'Empuan AI is writing an answer',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AiLabel(),
            const SizedBox(height: 12),
            SizedBox(
              height: 18,
              child: AnimatedBuilder(
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
            ),
          ],
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

class _SendError extends StatelessWidget {
  const _SendError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                'No answer. $message',
                style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textPrimary),
              ),
            ),
            EmButton(label: 'Retry', variant: EmButtonVariant.text, small: true, expand: false, onPressed: onRetry),
          ],
        ),
      ),
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
  });

  final TextEditingController controller;
  final String hint;
  final bool sending;
  final bool enabled;
  final int maxLength;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && !sending && controller.text.trim().isNotEmpty;
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
