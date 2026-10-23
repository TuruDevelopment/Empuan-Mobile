import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api.dart';
import '../../data/community_repository.dart';
import '../../ui/em_ui.dart';
import 'post_widgets.dart';

/// Returned when [PostScreen] closes, so the feed can show new counts or hide
/// a member the user just blocked.
class PostResult {
  const PostResult({required this.post, this.blockedAuthorId});

  final CommunityPost post;
  final int? blockedAuthorId;
}

class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  static const _maxLength = 500;

  final _repo = CommunityRepository();
  final _input = TextEditingController();

  late CommunityPost _post = widget.post;
  List<Reply>? _replies;
  String? _error;
  bool _liking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _loadReplies();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _error = null);
    try {
      final replies = await _repo.replies(_post.id);
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _post = _post.copyWith(comments: replies.length);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_replies == null) {
        setState(() => _error = e.message);
      } else {
        showEmToast(context, e.message);
      }
    }
  }

  Future<void> _like() async {
    if (_liking) return;
    _liking = true;
    await toggleLikeOptimistic(
      context,
      repo: _repo,
      post: _post,
      change: (f) {
        if (mounted) setState(() => _post = f(_post));
      },
    );
    _liking = false;
  }

  Future<void> _sendReply() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.addReply(_post.id, text);
      if (!mounted) return;
      _input.clear();
      FocusScope.of(context).unfocus();
      setState(() => _post = _post.copyWith(comments: _post.comments + 1));
      await _loadReplies();
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, 'Your reply wasn’t sent. ${e.message}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _close([int? blockedAuthorId]) {
    Navigator.of(context).pop(PostResult(post: _post, blockedAuthorId: blockedAuthorId));
  }

  void _postOptions() {
    showContentOptions(
      context,
      target: ReportTarget.communityPost,
      targetId: _post.id,
      text: _post.text,
      authorName: _post.authorName,
      authorId: _post.authorId,
      onBlocked: _close,
    );
  }

  void _replyOptions(Reply reply) {
    showContentOptions(
      context,
      target: ReportTarget.communityReply,
      targetId: reply.id,
      text: reply.text,
      authorName: reply.authorName,
      authorId: reply.authorId,
      onBlocked: (id) {
        if (id == _post.authorId) return _close(id);
        setState(() => _replies = _replies?.where((r) => r.authorId != id).toList());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<PostResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: EmTopBar(
          title: 'Post',
          actions: [EmIconButton(icon: Icons.more_horiz_rounded, label: 'Post options', onPressed: _postOptions)],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadReplies,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    AuthorLine(name: authorNameOf(_post.authorName), date: _post.date, large: true),
                    const SizedBox(height: 12),
                    SelectableText(
                      _post.text,
                      style: const TextStyle(fontSize: 17, height: 26 / 17, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LikeButton(liked: _post.liked, count: _post.likes, long: true, onPressed: _like),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text(
                        repliesLabel(_replies?.length ?? _post.comments),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    ..._repliesSection(),
                  ],
                ),
              ),
            ),
            _ReplyBar(
              controller: _input,
              sending: _sending,
              maxLength: _maxLength,
              onSend: _sendReply,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _repliesSection() {
    final replies = _replies;
    if (replies == null && _error != null) {
      return [EmStateView.error(message: _error!, onRetry: _loadReplies)];
    }
    if (replies == null) return const [EmLoading()];
    if (replies.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('No replies yet. Be the first to reply.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ),
      ];
    }
    final me = currentUserId;
    return [
      for (var i = 0; i < replies.length; i++) ...[
        if (i > 0) const Divider(),
        _ReplyTile(
          reply: replies[i],
          isOwn: me != null && replies[i].authorId == me,
          onOptions: () => _replyOptions(replies[i]),
        ),
      ],
    ];
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply, required this.isOwn, required this.onOptions});

  final Reply reply;
  final bool isOwn;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final name = isOwn ? 'You' : authorNameOf(reply.authorName);
    final time = formatRelative(reply.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: EmAvatar(name: authorNameOf(reply.authorName), size: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (time.isNotEmpty) TextSpan(text: ' · $time', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, height: 18 / 13),
                ),
                const SizedBox(height: 4),
                Text(reply.text, style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (!isOwn)
            Transform.translate(
              offset: const Offset(10, -10),
              child: EmIconButton(
                icon: Icons.more_horiz_rounded,
                label: 'Reply options',
                color: AppColors.textSecondary,
                onPressed: onOptions,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.controller, required this.sending, required this.maxLength, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final int maxLength;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = !sending && controller.text.trim().isNotEmpty;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.line2));
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
              readOnly: sending,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write a reply',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))),
                )
              : Opacity(
                  opacity: canSend ? 1 : 0.45,
                  child: EmIconButton(
                    icon: Icons.send_rounded,
                    label: 'Send reply',
                    style: EmIconButtonStyle.primary,
                    onPressed: canSend ? onSend : null,
                  ),
                ),
        ],
      ),
    );
  }
}
