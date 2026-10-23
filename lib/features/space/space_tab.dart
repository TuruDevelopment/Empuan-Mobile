import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../data/community_repository.dart';
import '../../ui/em_ui.dart';
import '../profile/legal_screen.dart';
import 'compose_screen.dart';
import 'post_screen.dart';
import 'post_widgets.dart';

enum _Filter { recent, mostLiked, mine }

/// Her Space tab: the community feed.
class SpaceTab extends StatefulWidget {
  const SpaceTab({super.key});

  @override
  State<SpaceTab> createState() => _SpaceTabState();
}

class _SpaceTabState extends State<SpaceTab> {
  final _repo = CommunityRepository();
  final _scroll = ScrollController();
  final Set<int> _liking = {};

  List<CommunityPost> _posts = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  _Filter _filter = _Filter.recent;

  /// Drops page results that arrive after a refresh started.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _error = null;
      _moreError = null;
      if (_posts.isEmpty) _loading = true;
    });
    try {
      final posts = await _repo.posts(page: 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts = posts;
        _page = 1;
        _hasMore = posts.length >= CommunityRepository.pageSize;
      });
      _fillViewport();
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;
      if (_posts.isEmpty) {
        setState(() => _error = e.message);
      } else {
        showEmToast(context, e.message);
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _moreError != null) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final next = await _repo.posts(page: _page + 1);
      if (!mounted || generation != _generation) return;
      final seen = _posts.map((p) => p.id).toSet();
      setState(() {
        _posts = [..._posts, ...next.where((p) => !seen.contains(p.id))];
        _page++;
        _hasMore = next.length >= CommunityRepository.pageSize;
      });
      _fillViewport();
    } on ApiException catch (e) {
      if (mounted && generation == _generation) setState(() => _moreError = e.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  /// Filters can leave too few posts to scroll; keep loading until the
  /// screen is full or there is nothing more.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients && _scroll.position.maxScrollExtent <= 0) _loadMore();
    });
  }

  List<CommunityPost> get _visible {
    switch (_filter) {
      case _Filter.recent:
        return _posts;
      case _Filter.mostLiked:
        return [..._posts]..sort((a, b) => b.likes.compareTo(a.likes));
      case _Filter.mine:
        final me = currentUserId;
        return me == null ? const [] : _posts.where((p) => p.authorId == me).toList();
    }
  }

  void _update(int id, CommunityPost Function(CommunityPost) change) {
    setState(() => _posts = [for (final p in _posts) p.id == id ? change(p) : p]);
  }

  void _removeAuthor(int authorId) {
    setState(() => _posts = _posts.where((p) => p.authorId != authorId).toList());
  }

  Future<void> _like(CommunityPost post) async {
    if (!_liking.add(post.id)) return;
    await toggleLikeOptimistic(context, repo: _repo, post: post, change: (f) => _update(post.id, f));
    _liking.remove(post.id);
  }

  Future<void> _compose() async {
    final posted = await pushScreen<bool>(context, const ComposeScreen());
    if (posted != true || !mounted) return;
    showEmToast(context, 'Posted to Her Space', icon: Icons.check_rounded);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _refresh();
  }

  Future<void> _open(CommunityPost post) async {
    final result = await pushScreen<PostResult>(context, PostScreen(post: post));
    if (result == null || !mounted) return;
    if (result.blockedAuthorId != null) {
      _removeAuthor(result.blockedAuthorId!);
    } else {
      _update(post.id, (_) => result.post);
    }
  }

  void _options(CommunityPost post) {
    showContentOptions(
      context,
      target: ReportTarget.communityPost,
      targetId: post.id,
      text: post.text,
      authorName: post.authorName,
      authorId: post.authorId,
      onBlocked: _removeAuthor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList.list(
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _composer(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: EmChipBar(
                  labels: const ['Recent', 'Most liked', 'My posts'],
                  selected: _filter.index,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onSelected: (i) {
                    setState(() => _filter = _Filter.values[i]);
                    _fillViewport();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ..._feed(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('Her Space', style: Theme.of(context).textTheme.headlineLarge)),
              const SizedBox(height: 4),
              Text('Ask, share and support each other', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        EmIconButton(
          icon: Icons.info_outline_rounded,
          label: 'Community guidelines',
          style: EmIconButtonStyle.soft,
          onPressed: () => pushScreen<void>(context, const LegalScreen(doc: LegalDoc.guidelines)),
        ),
      ],
    );
  }

  Widget _composer() {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: Session.user,
      builder: (_, user, __) => EmCard(
        onTap: _compose,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExcludeSemantics(child: EmAvatar(name: user?.name ?? 'Member')),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Share something with the community', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _feed() {
    if (_loading && _posts.isEmpty) {
      return [const SliverToBoxAdapter(child: EmLoading())];
    }
    if (_error != null && _posts.isEmpty) {
      return [SliverToBoxAdapter(child: EmStateView.error(message: _error!, onRetry: _refresh))];
    }
    final visible = _visible;
    if (visible.isEmpty && !_loadingMore && (_moreError != null || !_hasMore || _filter != _Filter.mine)) {
      return [SliverToBoxAdapter(child: _empty())];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _PostCard(
            post: visible[i],
            onOpen: () => _open(visible[i]),
            onLike: () => _like(visible[i]),
            onOptions: () => _options(visible[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(child: _footer()),
    ];
  }

  Widget _empty() {
    if (_filter == _Filter.mine) {
      return EmStateView(
        icon: Icons.edit_note_rounded,
        title: 'You haven’t posted yet',
        message: 'Your posts in Her Space show up here.',
        actionLabel: 'Write a post',
        onAction: _compose,
      );
    }
    return EmStateView(
      icon: Icons.forum_outlined,
      title: 'No posts yet',
      message: 'Be the first to share something.',
      actionLabel: 'Write a post',
      onAction: _compose,
    );
  }

  Widget _footer() {
    if (_loadingMore) return const EmLoading();
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Text(_moreError!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            EmButton(
              label: 'Load more',
              variant: EmButtonVariant.tonal,
              small: true,
              expand: false,
              onPressed: () {
                setState(() => _moreError = null);
                _loadMore();
              },
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onOpen, required this.onLike, required this.onOptions});

  final CommunityPost post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return EmCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorLine(name: authorNameOf(post.authorName), date: post.date, onOptions: onOptions),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              post.text,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 22 / 15, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Transform.translate(
            offset: const Offset(-10, 0),
            child: Row(
              children: [
                LikeButton(liked: post.liked, count: post.likes, onPressed: onLike),
                RepliesButton(count: post.comments, onPressed: onOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
