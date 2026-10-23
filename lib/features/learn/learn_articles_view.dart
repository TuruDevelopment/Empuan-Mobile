import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
import '../learning/widgets/learning_widgets.dart';
import 'article_screen.dart';

/// Articles segment of the Learn tab: Her Voice articles with topic filters.
class LearnArticlesView extends StatefulWidget {
  const LearnArticlesView({super.key, required this.repository});

  final ArticlesRepository repository;

  @override
  State<LearnArticlesView> createState() => _LearnArticlesViewState();
}

class _LearnArticlesViewState extends State<LearnArticlesView> {
  late Future<List<Article>> _articles = widget.repository.articles();
  List<ArticleCategory> _categories = const [];
  int? _categoryId;
  LearningEntrance _entrance = LearningEntrance();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.repository.categories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // Filters are optional; without them the chip row stays hidden.
    }
  }

  Future<void> _reload() async {
    final future = widget.repository.articles();
    setState(() {
      _articles = future;
    });
    if (_categories.isEmpty) await _loadCategories();
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  void _select(int? categoryId) {
    setState(() {
      _categoryId = categoryId;
      _entrance = LearningEntrance();
    });
  }

  String? _categoryName(int? id) {
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }

  void _open(Article article) {
    pushScreen<void>(context, ArticleScreen(article: article, categoryName: _categoryName(article.categoryId)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EmChipBar(
              labels: ['All', ..._categories.map((c) => c.name)],
              selected: _categoryId == null ? 0 : _categories.indexWhere((c) => c.id == _categoryId) + 1,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              onSelected: (i) => _select(i == 0 ? null : _categories[i - 1].id),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Article>>(
            future: _articles,
            builder: (context, snapshot) {
              final (key, child) = _state(snapshot);
              return EmStateSwitcher(stateKey: key, child: child);
            },
          ),
        ),
      ],
    );
  }

  (String, Widget) _state(AsyncSnapshot<List<Article>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return ('loading', const _ArticlesSkeleton());
    }
    if (snapshot.hasError) {
      return (
        'error',
        LearningScrollableState(
          onRefresh: _reload,
          child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
        ),
      );
    }
    final articles = snapshot.requireData.where((a) => _categoryId == null || a.categoryId == _categoryId).toList();
    if (articles.isEmpty) {
      return (
        'empty-$_categoryId',
        LearningScrollableState(
          onRefresh: _reload,
          child: EmStateView(
            icon: Icons.article_outlined,
            title: _categoryId == null ? 'No articles yet' : 'No articles in this topic yet',
            message: 'New Her Voice articles will show up here.',
          ),
        ),
      );
    }

    final rest = articles.skip(1).toList();
    final children = <Widget>[
      _FeaturedArticle(
          article: articles.first,
          category: _categoryName(articles.first.categoryId),
          onTap: () => _open(articles.first)),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 16),
        EmGroup(
          children: [
            for (final article in rest)
              _ArticleRow(article: article, category: _categoryName(article.categoryId), onTap: () => _open(article)),
          ],
        ),
      ],
    ];
    return (
      'content-$_categoryId',
      RefreshIndicator(
        onRefresh: _reload,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: children.length,
          itemBuilder: (_, i) => _entrance.wrap(i, children[i]),
        ),
      ),
    );
  }
}

String _metaLine(String? category, Article article) =>
    [if (category != null && category.isNotEmpty) category, '${article.readMinutes} min read'].join(' · ');

class _FeaturedArticle extends StatelessWidget {
  const _FeaturedArticle({required this.article, required this.category, required this.onTap});

  final Article article;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EmCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null)
            LearningThumb(url: article.imageUrl, width: double.infinity, height: 180, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_metaLine(category, article),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(article.title, style: Theme.of(context).textTheme.titleMedium),
                if (article.date != null) ...[
                  const SizedBox(height: 6),
                  Text(formatDate(article.date), style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, required this.category, required this.onTap});

  final Article article;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_metaLine(category, article),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(article.title,
                        style: const TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700)),
                    if (article.date != null) ...[
                      const SizedBox(height: 4),
                      Text(formatDate(article.date),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (article.imageUrl != null) ...[
                const SizedBox(width: 12),
                LearningThumb(url: article.imageUrl, width: 76, height: 76, radius: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticlesSkeleton extends StatelessWidget {
  const _ArticlesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const EmSkeleton(height: 180, radius: 20),
          const SizedBox(height: 12),
          const EmSkeleton(height: 12, width: 120),
          const SizedBox(height: 8),
          const EmSkeleton(height: 18),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++) ...[
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmSkeleton(height: 12, width: 110),
                      SizedBox(height: 8),
                      EmSkeleton(height: 16),
                      SizedBox(height: 6),
                      EmSkeleton(height: 16, width: 160),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                EmSkeleton(width: 76, height: 76),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
