import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/main_shell.dart';
import '../../data/account_repository.dart';
import '../../data/contacts_repository.dart';
import '../../data/content_repository.dart';
import '../../data/daily_quiz_repository.dart';
import '../../features/learning/models/learning_models.dart';
import '../../features/learning/services/learning_service.dart';
import '../../ui/em_ui.dart';
import '../ai/ai_chat_screen.dart';
import '../auth/form_motion.dart';
import '../daily/daily_quiz_screen.dart';
import '../learn/article_screen.dart';
import '../learning/screens/learning_course_detail_screen.dart';
import '../places/place_screen.dart';
import '../places/places_screen.dart';
import '../profile/animated_avatar.dart';
import '../profile/me_screen.dart';
import '../safety/contact_sheet.dart';
import '../safety/sos_controller.dart';

enum _Part { contacts, question, learning, articles, places }

/// Each section loads on its own so one failing endpoint only hides that section.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Contact>? _contacts;
  DailyQuestion? _question;
  bool _answeredToday = false;
  LearningHomeData? _learning;
  List<Article> _articles = const [];
  Map<int, String> _articleCategories = const {};
  List<Place> _places = const [];

  /// Sections still waiting for their first response; they show a skeleton.
  /// Pull-to-refresh keeps the current content instead.
  final Set<_Part> _pending = _Part.values.toSet();

  void _settle(_Part part) {
    if (mounted && _pending.contains(part)) setState(() => _pending.remove(part));
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadContacts(),
      _loadQuestion(),
      _loadLearning(),
      _loadArticles(),
      _loadPlaces(),
      if (Session.user.value == null) AccountRepository().fetchMe().then((_) {}, onError: (_) {}),
    ]);
  }

  Future<void> _loadContacts() async {
    try {
      final list = await SosController.instance.trustedContacts();
      if (mounted) setState(() => _contacts = list);
    } catch (_) {
      // Unknown: neither "ready" nor "no contacts" is shown.
    }
    _settle(_Part.contacts);
  }

  Future<void> _loadQuestion() async {
    try {
      final repo = DailyQuizRepository();
      final answered = await repo.answeredToday();
      final today = await repo.today();
      if (mounted) {
        setState(() {
          _answeredToday = answered;
          _question = today.isEmpty ? null : today.first;
        });
      }
    } catch (_) {}
    _settle(_Part.question);
  }

  Future<void> _loadLearning() async {
    try {
      final home = await LearningService().getHome();
      if (mounted) setState(() => _learning = home);
    } catch (_) {}
    _settle(_Part.learning);
  }

  Future<void> _loadArticles() async {
    try {
      final repo = ArticlesRepository();
      final articles = await repo.articles();
      Map<int, String> names = const {};
      try {
        names = {for (final c in await repo.categories()) c.id: c.name};
      } catch (_) {}
      if (mounted) {
        setState(() {
          _articles = articles.take(2).toList();
          _articleCategories = names;
        });
      }
    } catch (_) {}
    _settle(_Part.articles);
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await PlacesRepository().places();
      if (mounted) setState(() => _places = places.take(2).toList());
    } catch (_) {}
    _settle(_Part.places);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Good morning';
    if (hour < 15) return 'Good afternoon';
    if (hour < 19) return 'Good evening';
    return 'Good night';
  }

  Future<void> _addContact() async {
    if (await showContactSheet(context, kind: ContactKind.trusted)) await _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final continueCourse = _learning?.continueLearning.where((e) => e.completedAt == null).firstOrNull;
    final startCourse = continueCourse == null ? _learning?.recommendedCourses.firstOrNull : null;

    final course = continueCourse?.course ?? startCourse;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: staggered([
              ValueListenableBuilder<UserProfile?>(
                valueListenable: Session.user,
                builder: (context, user, _) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          // Fades to the personal greeting once the profile arrives.
                          AnimatedSwitcher(
                            duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
                            switchInCurve: EmMotion.enter,
                            switchOutCurve: EmMotion.exit,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [...previous, if (current != null) current],
                            ),
                            child: Text(
                              user == null ? _greeting() : '${_greeting()}, ${user.firstName}',
                              key: ValueKey(user?.firstName),
                              style: text.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Your profile',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => pushScreen(context, const MeScreen()),
                        child: AnimatedAvatar(name: user?.name ?? '', size: 44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                state: _pending.contains(_Part.contacts)
                    ? _SectionState.loading
                    : _contacts == null
                        ? _SectionState.hidden
                        : _contacts!.isEmpty
                            ? 'no-contacts'
                            : 'sos-ready',
                skeleton: const _CardSkeleton(height: 72),
                builder: () => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _contacts!.isEmpty ? _NoContactsCard(onAdd: _addContact) : _SosReadyCard(contacts: _contacts!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AskAiCard(onTap: () => openEmpuanAi(context)),
              ),
              _Section(
                state: _pending.contains(_Part.question)
                    ? _SectionState.loading
                    : _question == null
                        ? _SectionState.hidden
                        : 'question',
                skeleton: const _CardSkeleton(height: 136),
                builder: () => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QuestionCard(question: _question!, answered: _answeredToday, onOpen: () async {
                    await pushScreen(context, const DailyQuizScreen());
                    await _loadQuestion();
                  }),
                ),
              ),
              _Section(
                state: _pending.contains(_Part.learning)
                    ? _SectionState.loading
                    : course == null
                        ? _SectionState.hidden
                        : 'course',
                skeleton: const _CardSkeleton(height: 100, header: true),
                builder: () => Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmSectionHeader(
                        continueCourse != null ? 'Continue learning' : 'Start learning',
                        actionLabel: 'All courses',
                        onAction: () => ShellScope.maybeOf(context)?.goTo(AppTab.learn),
                      ),
                      const SizedBox(height: 8),
                      _CourseCard(
                        course: course!,
                        summary: continueCourse?.summary,
                        onTap: () async {
                          await pushScreen(context, LearningCourseDetailScreen(slug: course.slug, service: LearningService()));
                          await _loadLearning();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _Section(
                state: _pending.contains(_Part.articles)
                    ? _SectionState.loading
                    : _articles.isEmpty
                        ? _SectionState.hidden
                        : 'articles',
                skeleton: const _CardSkeleton(height: 178, header: true),
                builder: () => Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmSectionHeader('From Her Voice', actionLabel: 'More articles', onAction: () => ShellScope.maybeOf(context)?.goTo(AppTab.learn)),
                      const SizedBox(height: 8),
                      EmGroup(
                        children: [
                          for (final a in _articles)
                            _ArticleRow(
                              article: a,
                              category: _articleCategories[a.categoryId],
                              onTap: () => pushScreen(context, ArticleScreen(article: a, categoryName: _articleCategories[a.categoryId])),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _Section(
                state: _pending.contains(_Part.places)
                    ? _SectionState.loading
                    : _places.isEmpty
                        ? _SectionState.hidden
                        : 'places',
                skeleton: const _PlacesSkeleton(),
                builder: () => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmSectionHeader('Places for her', actionLabel: 'See all', onAction: () => pushScreen(context, const PlacesScreen())),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < _places.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: _PlaceTile(place: _places[i])),
                          ],
                          if (_places.length == 1) const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

abstract final class _SectionState {
  static const loading = 'loading';
  static const hidden = 'hidden';
}

/// One home section: a skeleton while its first load is in flight, then a
/// cross-fade to the content (or a smooth collapse if there's nothing to show).
class _Section extends StatelessWidget {
  const _Section({required this.state, required this.skeleton, required this.builder});

  /// [_SectionState.loading], [_SectionState.hidden], or any other key for
  /// content; a new key cross-fades (e.g. "no contacts" to "SOS ready").
  final String state;
  final Widget skeleton;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      curve: EmMotion.enter,
      alignment: Alignment.topCenter,
      child: EmStateSwitcher(
        stateKey: state,
        child: switch (state) {
          _SectionState.loading => skeleton,
          _SectionState.hidden => const SizedBox(width: double.infinity),
          _ => builder(),
        },
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height, this.header = false});

  final double height;

  /// Also show a section-title placeholder above the card.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Padding(
        padding: EdgeInsets.only(top: header ? 8 : 0, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header) ...[const EmSkeleton(width: 140, height: 18, radius: 8), const SizedBox(height: 14)],
            EmSkeleton(height: height, radius: 20),
          ],
        ),
      ),
    );
  }
}

class _PlacesSkeleton extends StatelessWidget {
  const _PlacesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmSkeleton(width: 140, height: 18, radius: 8),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: EmSkeleton(height: 150, radius: 20)),
                SizedBox(width: 12),
                Expanded(child: EmSkeleton(height: 150, radius: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SosReadyCard extends StatelessWidget {
  const _SosReadyCard({required this.contacts});

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final names = contacts.length > 2 ? '${contacts.first.name} and ${contacts.length - 1} others' : namesList(contacts);
    return EmCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => ShellScope.maybeOf(context)?.goTo(AppTab.safety),
      child: Row(
        children: [
          const EmIconTile(Icons.verified_user_outlined, tone: EmTileTone.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOS is ready', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('$names will get your location', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.quietIcon),
        ],
      ),
    );
  }
}

class _NoContactsCard extends StatelessWidget {
  const _NoContactsCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmCard(
      borderColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmIconTile(Icons.shield_outlined, tone: EmTileTone.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS can’t reach anyone yet', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text('Add at least one trusted contact so your alert has somewhere to go.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EmButton(label: 'Add trusted contact', variant: EmButtonVariant.danger, small: true, expand: false, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _AskAiCard extends StatelessWidget {
  const _AskAiCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Ask Empuan AI', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line2, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(child: Text('Ask about safety, work, money…', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 15))),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.answered, required this.onOpen});

  final DailyQuestion question;
  final bool answered;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EmCard(
      color: AppColors.blush,
      borderColor: AppColors.blush,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: EmCaption('Today’s question', color: AppColors.primary)),
              EmAnimatedSwap(
                valueKey: answered,
                child: Text(answered ? 'Done' : '1 min', style: text.labelMedium?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.prompt, style: text.titleMedium),
          const SizedBox(height: 12),
          EmButton(label: answered ? 'See today’s answers' : 'Answer', small: true, expand: false, onPressed: onOpen),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap, this.summary});

  final LearningCourse course;
  final LearningProgressSummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EmCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 76,
              child: course.thumbnailUrl == null
                  ? const ColoredBox(color: AppColors.blush, child: Icon(Icons.menu_book_outlined, color: AppColors.secondary))
                  : Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.blush),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.category != null) EmTag(course.category!.name),
                const SizedBox(height: 6),
                Text(course.title, style: text.titleSmall),
                const SizedBox(height: 6),
                if (summary != null && summary!.totalLessons > 0)
                  Row(
                    children: [
                      Expanded(child: EmProgressBar(value: summary!.completedLessons / summary!.totalLessons)),
                      const SizedBox(width: 8),
                      Text('${summary!.completedLessons} of ${summary!.totalLessons}', style: text.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Text('${course.estimatedMinutes} min${course.certificateEnabled ? ' · Certificate' : ''}', style: text.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, required this.onTap, this.category});

  final Article article;
  final String? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [if (category != null) category!, '${article.readMinutes} min read'].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: article.imageUrl == null
                    ? const ColoredBox(color: AppColors.blush)
                    : Image.network(article.imageUrl!, fit: BoxFit.cover, excludeFromSemantics: true, errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.blush)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final status = place.openStatus();
    return EmCard(
      padding: const EdgeInsets.all(10),
      onTap: () => pushScreen(context, PlaceScreen(place: place, heroTag: 'home-place-photo-${place.id}')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlacePhoto(place: place, height: 96, width: double.infinity, radius: 12, heroTag: 'home-place-photo-${place.id}'),
          const SizedBox(height: 8),
          Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (status != null) ...[
            const SizedBox(height: 2),
            Text(status.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
