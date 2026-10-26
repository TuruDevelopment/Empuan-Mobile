import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../data/community_repository.dart';
import '../../ui/em_ui.dart';
import '../moderation/report_sheet.dart';

int? get currentUserId => Session.user.value?.id;

String authorNameOf(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? 'Member' : trimmed;
}

String repliesLabel(int n) => n == 1 ? '1 reply' : '$n replies';

/// Likes optimistically, then applies the server count. Rolls back and
/// explains on failure. [change] must apply the given update to the stored post.
Future<void> toggleLikeOptimistic(
  BuildContext context, {
  required CommunityRepository repo,
  required CommunityPost post,
  required void Function(CommunityPost Function(CommunityPost) update) change,
}) async {
  final wasLiked = post.liked;
  final before = post.likes;
  change((p) => p.copyWith(liked: !wasLiked, likes: math.max(0, before + (wasLiked ? -1 : 1))));
  try {
    final (liked, total) = await repo.toggleLike(post.id);
    change((p) => p.copyWith(liked: liked, likes: total));
  } on ApiException catch (e) {
    change((p) => p.copyWith(liked: wasLiked, likes: before));
    if (context.mounted) showEmToast(context, 'Couldn’t update your like. ${e.message}');
  }
}

enum _ContentAction { report, block, copy }

/// The ⋯ sheet for posts and replies: report, block the author, copy text.
/// Calls [onBlocked] with the author's id once they are blocked.
Future<void> showContentOptions(
  BuildContext context, {
  required ReportTarget target,
  required int targetId,
  required String text,
  String? authorName,
  int? authorId,
  ValueChanged<int>? onBlocked,
}) async {
  final name = authorNameOf(authorName);
  final isOwn = authorId != null && authorId == currentUserId;
  final isPost = target == ReportTarget.communityPost;
  final action = await showEmSheet<_ContentAction>(
    context,
    builder: (ctx) {
      final rows = [
        if (!isOwn)
          _OptionRow(
            icon: Icons.outlined_flag_rounded,
            label: isPost ? 'Report post' : 'Report reply',
            onTap: () => Navigator.of(ctx).pop(_ContentAction.report),
          ),
        if (!isOwn && authorId != null)
          _OptionRow(
            icon: Icons.block_rounded,
            label: 'Block $name',
            danger: true,
            onTap: () => Navigator.of(ctx).pop(_ContentAction.block),
          ),
        _OptionRow(
          icon: Icons.copy_rounded,
          label: 'Copy text',
          onTap: () => Navigator.of(ctx).pop(_ContentAction.copy),
        ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++)
            EmFadeSlideIn(index: i, offset: const Offset(0, 8), duration: EmMotion.medium, child: rows[i]),
        ],
      );
    },
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _ContentAction.report:
      await showReportSheet(context, target: target, targetId: '$targetId', authorName: name, authorId: authorId);
    case _ContentAction.block:
      if (await confirmBlock(context, name: name, userId: authorId!)) onBlocked?.call(authorId);
    case _ContentAction.copy:
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) showEmToast(context, 'Text copied');
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label, required this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      ),
    );
  }
}

/// Heart with count. [long] shows "14 likes" instead of "14".
class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.liked, required this.count, required this.onPressed, this.long = false});

  final bool liked;
  final int count;
  final VoidCallback? onPressed;
  final bool long;

  @override
  Widget build(BuildContext context) {
    final color = liked ? AppColors.danger : AppColors.textSecondary;
    final countLabel = count == 1 ? '1 like' : '$count likes';
    return Semantics(
      button: true,
      toggled: liked,
      label: 'Like, $countLabel',
      child: ExcludeSemantics(
        child: _ActionChip(
          onPressed: onPressed,
          icon: EmLikeIcon(liked: liked, size: 20),
          label: long ? countLabel : '$count',
          color: color,
        ),
      ),
    );
  }
}

class RepliesButton extends StatelessWidget {
  const RepliesButton({super.key, required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${repliesLabel(count)}. Open post',
      child: ExcludeSemantics(
        child: _ActionChip(
          onPressed: onPressed,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppColors.textSecondary),
          label: repliesLabel(count),
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.onPressed, required this.icon, required this.label, required this.color});

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 6),
              EmAnimatedSwap(
                valueKey: label,
                child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar, name and relative time, with an optional ⋯ button.
class AuthorLine extends StatelessWidget {
  const AuthorLine(
      {super.key, required this.name, required this.date, this.onOptions, this.optionsLabel = 'Post options', this.large = false});

  final String name;
  final DateTime? date;
  final VoidCallback? onOptions;
  final String optionsLabel;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(child: EmAvatar(name: name, size: large ? 40 : 32)),
        SizedBox(width: large ? 12 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: large ? 15 : 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (date != null)
                Text(formatRelative(date), style: const TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (onOptions != null)
          EmIconButton(icon: Icons.more_horiz_rounded, label: optionsLabel, color: AppColors.textSecondary, onPressed: onOptions),
      ],
    );
  }
}

/// Loading placeholder shaped like the feed's post cards.
class PostSkeletonList extends StatelessWidget {
  const PostSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading posts',
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EmCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        EmSkeleton(width: 32, height: 32, radius: 16),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [EmSkeleton(width: 90, height: 12), SizedBox(height: 6), EmSkeleton(width: 50, height: 10)],
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    EmSkeleton(height: 14),
                    SizedBox(height: 8),
                    EmSkeleton(height: 14, width: 220),
                    SizedBox(height: 14),
                    EmSkeleton(height: 12, width: 110),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading placeholder shaped like a list of replies.
class ReplySkeletonList extends StatelessWidget {
  const ReplySkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading replies',
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmSkeleton(width: 32, height: 32, radius: 16),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmSkeleton(width: 100, height: 12),
                        SizedBox(height: 8),
                        EmSkeleton(height: 14),
                        SizedBox(height: 6),
                        EmSkeleton(height: 14, width: 160)
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
