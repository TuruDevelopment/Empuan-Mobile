import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/account_repository.dart';
import '../../data/community_repository.dart';
import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
import '../learning/widgets/learning_widgets.dart';
import '../moderation/report_sheet.dart';

/// A Her Voice article with its comments and a comment box pinned below.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.article, this.categoryName, this.repository});

  final Article article;
  final String? categoryName;
  final ArticlesRepository? repository;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final ArticlesRepository _repo = widget.repository ?? ArticlesRepository();
  final _input = TextEditingController();
  late Future<List<Reply>> _comments = _loadComments();
  final Set<int> _hiddenAuthors = {};
  Set<int>? _known;

  /// Comments that arrived since the last load; only these animate in.
  Set<int> _fresh = const {};
  bool _sending = false;

  Future<List<Reply>> _loadComments() async {
    final list = await _repo.comments(widget.article.id);
    final ids = list.map((r) => r.id).toSet();
    final known = _known;
    if (known != null) _fresh = ids.difference(known);
    _known = ids;
    return list;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _reloadComments() async {
    final future = _loadComments();
    setState(() {
      _comments = future;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  Future<void> _post() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.addComment(widget.article.id, text);
      if (!mounted) return;
      _input.clear();
      FocusScope.of(context).unfocus();
      await _reloadComments();
    } catch (error) {
      if (mounted) showEmToast(context, '$error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _share() async {
    final a = widget.article;
    await SharePlus.instance.share(ShareParams(text: '${a.title}\nFrom Her Voice on Empuan', subject: a.title));
  }

  Future<void> _commentOptions(Reply reply) async {
    final me = Session.user.value?.id;
    final canBlock = reply.authorId != null && reply.authorId != me;
    final action = await showEmSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          EmGroup(
            children: [
              EmRow(
                leading: const EmIconTile(Icons.flag_outlined),
                title: 'Report comment',
                onTap: () => Navigator.of(ctx).pop('report'),
              ),
              if (canBlock)
                EmRow(
                  leading: const EmIconTile(Icons.block_rounded, tone: EmTileTone.danger),
                  title: 'Block ${reply.authorName}',
                  titleColor: AppColors.danger,
                  onTap: () => Navigator.of(ctx).pop('block'),
                ),
            ],
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'report') {
      await showReportSheet(
        context,
        target: ReportTarget.articleComment,
        targetId: '${reply.id}',
        authorName: reply.authorName,
        authorId: reply.authorId,
      );
    } else if (action == 'block') {
      final blocked = await confirmBlock(context, name: reply.authorName, userId: reply.authorId!);
      if (blocked && mounted) setState(() => _hiddenAuthors.add(reply.authorId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.of(context).padding.top;
    final hasImage = article.imageUrl != null;
    final paragraphs = htmlToParagraphs(article.body);
    final meta = [if (article.date != null) formatDate(article.date), '${article.readMinutes} min read'].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _reloadComments,
                  edgeOffset: top,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      if (hasImage)
                        Semantics(
                          image: true,
                          label: 'Article image',
                          child: LearningThumb(
                              url: article.imageUrl, width: double.infinity, height: 260 + top, radius: 0),
                        )
                      else
                        SizedBox(height: top + 64),
                      EmFadeSlideIn(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.categoryName == null ? 'Her Voice' : 'Her Voice · ${widget.categoryName}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Text(article.title, style: text.headlineLarge),
                              const SizedBox(height: 8),
                              Text(meta, style: text.bodySmall),
                              const SizedBox(height: 16),
                              for (final paragraph in paragraphs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: SelectableText(paragraph, style: text.bodyLarge),
                                ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      ),
                      _buildComments(context),
                    ],
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  child: EmIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    style: EmIconButtonStyle.soft,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  right: 12,
                  child: EmIconButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share article',
                    style: EmIconButtonStyle.soft,
                    onPressed: _share,
                  ),
                ),
              ],
            ),
          ),
          _CommentBar(controller: _input, sending: _sending, onSend: _post),
        ],
      ),
    );
  }

  Widget _buildComments(BuildContext context) {
    return FutureBuilder<List<Reply>>(
      future: _comments,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final all = snapshot.data ?? const <Reply>[];
        final comments = all.where((r) => !_hiddenAuthors.contains(r.authorId)).toList();

        Widget body;
        String key;
        if (loading) {
          key = 'loading';
          body = const Padding(
              padding: EdgeInsets.only(top: 8),
              child: EmSkeletonList(count: 2, thumbnail: 32, padding: EdgeInsets.zero));
        } else if (snapshot.hasError) {
          key = 'error';
          body = EmStateView.error(message: '${snapshot.error}', onRetry: _reloadComments);
        } else if (comments.isEmpty) {
          key = 'empty';
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No comments yet. Start the conversation.', style: Theme.of(context).textTheme.bodySmall),
          );
        } else {
          key = 'list';
          body = Column(
            children: [
              for (final reply in comments)
                KeyedSubtree(
                  key: ValueKey(reply.id),
                  child: _fresh.contains(reply.id)
                      ? EmFadeSlideIn(child: _CommentTile(reply: reply, onOptions: _commentOptions))
                      : _CommentTile(reply: reply, onOptions: _commentOptions),
                ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Comments', style: Theme.of(context).textTheme.titleLarge)),
                  if (!loading && !snapshot.hasError)
                    EmAnimatedSwap(
                      valueKey: comments.length,
                      child: Text('${comments.length}', style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
                curve: EmMotion.enter,
                alignment: Alignment.topCenter,
                child: EmStateSwitcher(stateKey: key, child: body),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.reply, required this.onOptions});

  final Reply reply;
  final ValueChanged<Reply> onOptions;

  @override
  Widget build(BuildContext context) {
    final mine = reply.authorId != null && reply.authorId == Session.user.value?.id;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: EmAvatar(name: reply.authorName, size: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: reply.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (reply.date != null)
                                TextSpan(
                                    text: ' · ${formatRelative(reply.date)}',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      if (!mine)
                        EmIconButton(
                          icon: Icons.more_horiz_rounded,
                          label: 'Comment options',
                          color: AppColors.textSecondary,
                          onPressed: () => onOptions(reply),
                        ),
                    ],
                  ),
                ),
                Text(reply.text, style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBar extends StatelessWidget {
  const _CommentBar({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              ValueListenableBuilder<UserProfile?>(
                valueListenable: Session.user,
                builder: (_, user, __) => EmAvatar(name: user?.name ?? 'You', size: 32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a comment',
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppColors.line2, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) => sending
                    ? const SizedBox(
                        width: 44,
                        height: 44,
                        child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.4)),
                      )
                    : EmIconButton(
                        icon: Icons.send_rounded,
                        label: 'Post comment',
                        style: EmIconButtonStyle.primary,
                        onPressed: value.text.trim().isEmpty ? null : onSend,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
