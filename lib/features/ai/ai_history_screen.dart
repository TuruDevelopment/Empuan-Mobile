import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/collapse_out.dart';
import '../../data/api.dart';
import '../../models/chat_message.dart';
import '../../services/chatbot_service.dart';
import '../../ui/em_ui.dart';

/// What the user picked in [AiHistoryScreen]: a past chat, or a new chat
/// when [sessionId] is null.
class AiHistoryResult {
  const AiHistoryResult(this.sessionId, {this.title});

  final String? sessionId;

  /// The server title of the picked chat, when it has one.
  final String? title;
}

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key, this.onDeleted, this.service});

  @visibleForTesting
  final ChatbotService? service;

  /// Called after a chat is deleted, so the open chat can reset if needed.
  final ValueChanged<String>? onDeleted;

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  late final _service = widget.service ?? ChatbotService();
  List<ChatSession>? _sessions;
  String? _error;

  /// True for the frame after the first load, so rows stagger in once.
  bool _stagger = false;
  final Set<String> _leaving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final sessions = await _service.getSessions();
      if (!mounted) return;
      if (_sessions == null) {
        _stagger = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _stagger = false);
      }
      setState(() => _sessions = sessions);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_sessions == null) {
        setState(() => _error = e.message);
      } else {
        showEmToast(context, e.message);
      }
    }
  }

  void _open(ChatSession s) => Navigator.of(context).pop(AiHistoryResult(s.sessionId, title: s.title));

  void _newChat() => Navigator.of(context).pop(const AiHistoryResult(null));

  Future<void> _confirmDelete(ChatSession s) async {
    final confirmed = await showEmSheet<bool>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmSheetHeader(
            title: 'Delete “${_shorten(s.displayTitle)}”?',
            message: 'The whole conversation is removed from your account. This can’t be undone.',
          ),
          const SizedBox(height: 20),
          EmButton(label: 'Delete chat', variant: EmButtonVariant.danger, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
          EmButton(label: 'Cancel', variant: EmButtonVariant.text, onPressed: () => Navigator.of(ctx).pop(false)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteSession(s.sessionId);
      if (!mounted) return;
      setState(() => _leaving.add(s.sessionId));
      widget.onDeleted?.call(s.sessionId);
      showEmToast(context, 'Chat deleted');
      await afterCollapse(context, () {
        if (!mounted) return;
        setState(() {
          _sessions = _sessions?.where((x) => x.sessionId != s.sessionId).toList();
          _leaving.remove(s.sessionId);
        });
      });
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, 'Couldn’t delete this chat. ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    return Scaffold(
      appBar: const EmTopBar(title: 'Past chats'),
      body: EmStateSwitcher(
        stateKey: _error != null && sessions == null
            ? 'error'
            : sessions == null
                ? 'loading'
                : sessions.isEmpty
                    ? 'empty'
                    : 'list',
        child: _error != null && sessions == null
            ? Center(child: EmStateView.error(message: _error!, onRetry: _load))
            : sessions == null
                ? const EmSkeletonList(count: 5, thumbnail: 0)
                : RefreshIndicator(onRefresh: _load, child: _list(sessions)),
      ),
      bottomNavigationBar: sessions == null || sessions.isEmpty
          ? null
          : EmBottomBar(
              bordered: false,
              child: EmButton(label: 'New chat', icon: Icons.add_rounded, onPressed: _newChat),
            ),
    );
  }

  Widget _list(List<ChatSession> sessions) {
    if (sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          EmStateView(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No past chats',
            message: 'Chats you have with Empuan AI are saved here.',
            actionLabel: 'Start a new chat',
            onAction: _newChat,
          ),
        ],
      );
    }

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final thisWeek = sessions.where((s) => !s.lastMessage.isBefore(weekStart)).toList();
    final earlier = sessions.where((s) => s.lastMessage.isBefore(weekStart)).toList();

    var index = 0;
    List<Widget> section(String label, List<ChatSession> items) {
      return [
        EmFadeSlideIn(
          index: index++,
          duration: _stagger ? EmMotion.slow : Duration.zero,
          child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: EmCaption(label)),
        ),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                CollapseOut(
                  key: ValueKey(items[i].sessionId),
                  visible: !_leaving.contains(items[i].sessionId),
                  child: EmFadeSlideIn(
                    index: index++,
                    duration: _stagger ? EmMotion.slow : Duration.zero,
                    child: Column(children: [if (i > 0) const Divider(height: 1), _row(items[i], now)]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ];
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (thisWeek.isNotEmpty) ...section('This week', thisWeek),
        if (earlier.isNotEmpty) ...[
          if (thisWeek.isNotEmpty) const SizedBox(height: 8),
          ...section('Earlier', earlier),
        ],
      ],
    );
  }

  Widget _row(ChatSession s, DateTime now) {
    final hasTitle = s.title != null && s.title!.trim().isNotEmpty;
    final subtitle =
        hasTitle && s.preview.trim().isNotEmpty ? s.preview.trim() : '${s.messageCount} ${s.messageCount == 1 ? 'message' : 'messages'}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(s),
        onLongPress: () => _confirmDelete(s),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_shortDate(s.lastMessage, now), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                EmIconButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete chat',
                  color: AppColors.textSecondary,
                  onPressed: () => _confirmDelete(s),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _shorten(String text) {
  final line = text.split('\n').first.trim();
  return line.length > 40 ? '${line.substring(0, 40).trimRight()}…' : line;
}

/// "Today", "Tue" within the week, then "12 Oct".
String _shortDate(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return DateFormat('EEE').format(date);
  if (date.year == now.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM yyyy').format(date);
}
