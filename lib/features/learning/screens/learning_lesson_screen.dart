import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_progress_sync_service.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';
import 'learning_quiz_screen.dart';

class LearningLessonScreen extends StatefulWidget {
  const LearningLessonScreen({
    super.key,
    required this.lessonId,
    required this.canTrackProgress,
    this.service,
    this.course,
  });

  final int lessonId;
  final LearningService? service;
  final bool canTrackProgress;

  /// Gives the lesson its place in the course. Fetched when not passed.
  final LearningCourse? course;

  @override
  State<LearningLessonScreen> createState() => _LearningLessonScreenState();
}

class _LearningLessonScreenState extends State<LearningLessonScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  late final LearningProgressSyncService _progressSync = LearningProgressSyncService(_service);
  late Future<LearningLesson> _lessonFuture;
  LearningCourse? _course;
  late bool _canTrack = widget.canTrackProgress;
  bool _saving = false;
  bool _enrolling = false;
  final _entrance = LearningEntrance();

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _lessonFuture = _loadLesson();
  }

  Future<LearningLesson> _loadLesson() async {
    final lesson = await _service.getLesson(widget.lessonId);
    if (_course == null && lesson.courseSlug.isNotEmpty) {
      try {
        final course = await _service.getCourse(lesson.courseSlug);
        if (mounted) setState(() => _course = course);
      } catch (_) {
        // The lesson still works without its position in the course.
      }
    }
    return lesson;
  }

  Future<void> _reload() async {
    final future = _loadLesson();
    setState(() {
      _lessonFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  List<LearningLessonSummary> get _lessons => _course?.lessons.toList() ?? const [];

  int get _index => _lessons.indexWhere((l) => l.id == widget.lessonId);

  LearningLessonSummary? _neighbour(int offset) {
    final i = _index;
    if (i < 0) return null;
    final j = i + offset;
    return j >= 0 && j < _lessons.length ? _lessons[j] : null;
  }

  void _goTo(LearningLessonSummary lesson) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LearningLessonScreen(
          lessonId: lesson.id,
          service: _service,
          canTrackProgress: _canTrack,
          course: _course,
        ),
      ),
    );
  }

  void _continue() {
    final next = _neighbour(1);
    final canOpenNext = next != null && (_canTrack || next.isPreview);
    if (canOpenNext) {
      _goTo(next);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _markDoneAndContinue(bool alreadyDone) async {
    if (alreadyDone) {
      _continue();
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _progressSync.completeLesson(widget.lessonId);
      if (!mounted) return;
      if (!result.synced) showEmToast(context, 'Saved on this phone. It will sync when you’re back online.');
      _continue();
    } catch (error) {
      if (mounted) showEmToast(context, '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enroll(LearningLesson lesson) async {
    setState(() => _enrolling = true);
    try {
      await _service.enroll(lesson.courseSlug);
      final course = await _service.getCourse(lesson.courseSlug);
      if (!mounted) return;
      setState(() {
        _canTrack = true;
        _course = course;
      });
      showEmToast(context, 'You’re enrolled. Your progress will be saved.', icon: Icons.check_rounded);
    } catch (error) {
      if (mounted) showEmToast(context, '$error');
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _index;
    final total = _lessons.length;
    return FutureBuilder<LearningLesson>(
      future: _lessonFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final lesson = loading ? null : snapshot.data;
        final done = lesson?.progress?.isCompleted == true;

        Widget body;
        String key;
        if (loading) {
          key = 'loading';
          body = const _LessonSkeleton();
        } else if (snapshot.hasError) {
          key = 'error';
          body = LearningScrollableState(
            onRefresh: _reload,
            child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
          );
        } else {
          key = 'content';
          body = _LessonContent(
            lesson: lesson!,
            entrance: _entrance,
            canTrackProgress: _canTrack,
            service: _service,
            onQuizClosed: _reload,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: LearningProgressTopBar(
            closeLabel: 'Close lesson',
            onClose: () => Navigator.of(context).maybePop(),
            caption: index >= 0 ? 'Lesson ${index + 1} of $total' : 'Lesson',
            progress: index >= 0 && total > 0 ? (index + 1) / total : null,
          ),
          body: EmStateSwitcher(stateKey: key, child: body),
          bottomNavigationBar: lesson == null
              ? null
              : EmBottomBar(
                  child: Row(
                    children: [
                      EmIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Previous lesson',
                        style: EmIconButtonStyle.soft,
                        size: 52,
                        onPressed: _neighbour(-1) == null ? null : () => _goTo(_neighbour(-1)!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _canTrack
                            ? EmButton(
                                label: done
                                    ? (_neighbour(1) == null ? 'Back to course' : 'Next lesson')
                                    : 'Mark done and continue',
                                loading: _saving,
                                onPressed: () => _markDoneAndContinue(done),
                              )
                            : EmButton(
                                label: 'Enroll to continue',
                                loading: _enrolling,
                                onPressed: lesson.courseSlug.isEmpty ? null : () => _enroll(lesson),
                              ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.lesson,
    required this.entrance,
    required this.canTrackProgress,
    required this.service,
    required this.onQuizClosed,
  });

  final LearningLesson lesson;
  final LearningEntrance entrance;
  final bool canTrackProgress;
  final LearningService service;
  final Future<void> Function() onQuizClosed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final media = lesson.mediaUrl;
    final hasMedia = media != null && media.isNotEmpty;
    final paragraphs = htmlToParagraphs(lesson.body);

    final children = <Widget>[
      if (hasMedia && lesson.type == 'video') ...[_VideoLesson(url: media), const SizedBox(height: 18)],
      if (hasMedia && lesson.type == 'infographic') ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            media,
            fit: BoxFit.contain,
            semanticLabel: 'Infographic: ${lesson.title}',
            errorBuilder: (_, __, ___) => const _MediaError(),
          ),
        ),
        const SizedBox(height: 18),
      ],
      if (lesson.sectionTitle.isNotEmpty) ...[EmCaption(lesson.sectionTitle), const SizedBox(height: 6)],
      Text(lesson.title, style: text.headlineMedium),
      if (lesson.summary != null && lesson.summary!.trim().isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(lesson.summary!, style: text.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      ],
      if (!canTrackProgress) ...[
        const SizedBox(height: 14),
        const EmNote(
          icon: Icons.visibility_outlined,
          child: Text('This is a free preview. Enroll to save your progress and take the quiz.'),
        ),
      ],
      if (paragraphs.isNotEmpty) ...[
        const SizedBox(height: 18),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SelectableText(paragraph, style: text.bodyLarge),
          ),
      ],
      if (lesson.content != null)
        for (final entry in lesson.content!.entries) ..._structured(context, entry.key, entry.value),
      if (lesson.hasQuiz && canTrackProgress) ...[
        const SizedBox(height: 8),
        _QuizCard(lesson: lesson, service: service, onClosed: onQuizClosed),
      ],
      if (lesson.sources.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Sources', style: text.titleMedium),
        const SizedBox(height: 10),
        for (final source in lesson.sources)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: LearningSourceRow(source: source)),
      ],
      const SizedBox(height: 16),
      Text(learningDisclaimer, style: text.bodySmall),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: children.length,
      itemBuilder: (_, i) => entrance.wrap(i, children[i]),
    );
  }

  /// Renders the lesson's structured `content` map as headed cards.
  List<Widget> _structured(BuildContext context, String key, dynamic value) {
    final text = Theme.of(context).textTheme;
    final items = value is List ? value : [value];
    return [
      const SizedBox(height: 8),
      Text(humanize(key), style: text.titleMedium),
      const SizedBox(height: 10),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: EmCard(padding: const EdgeInsets.all(14), child: _StructuredItem(item)),
        ),
      const SizedBox(height: 8),
    ];
  }
}

class _StructuredItem extends StatelessWidget {
  const _StructuredItem(this.item);

  final dynamic item;

  String? _pick(Map map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final value = item;
    if (value is! Map) return Text('$value', style: Theme.of(context).textTheme.bodyMedium);

    final figure = _pick(value, ['value', 'figure', 'percent', 'amount']);
    final title = _pick(value, ['title', 'label', 'name', 'heading']);
    final detail = _pick(value, ['description', 'text', 'body', 'detail']);
    final rest = value.entries
        .where((e) => ![
              'value',
              'figure',
              'percent',
              'amount',
              'title',
              'label',
              'name',
              'heading',
              'description',
              'text',
              'body',
              'detail'
            ].contains(e.key))
        .map((e) => '${humanize(e.key.toString())}: ${e.value}')
        .join('\n');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (figure != null) ...[
          SizedBox(
            width: 56,
            child: Text(figure, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (detail != null) Text(detail, style: Theme.of(context).textTheme.bodySmall),
              if (rest.isNotEmpty) Text(rest, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizCard extends StatefulWidget {
  const _QuizCard({required this.lesson, required this.service, required this.onClosed});

  final LearningLesson lesson;
  final LearningService service;
  final Future<void> Function() onClosed;

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  late final Future<LearningQuiz> _quiz = widget.service.getQuiz(widget.lesson.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningQuiz>(
      future: _quiz,
      builder: (context, snapshot) {
        final quiz = snapshot.data;
        final count = quiz?.questions.length ?? 0;
        final subtitle =
            quiz == null ? 'Quiz' : '$count ${count == 1 ? 'question' : 'questions'} · pass with ${quiz.passingScore}%';
        return EmCard(
          color: AppColors.blush,
          borderColor: AppColors.blush,
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                  builder: (_) => LearningQuizScreen(lessonId: widget.lesson.id, service: widget.service)),
            );
            await widget.onClosed();
          },
          child: Row(
            children: [
              const EmIconTile(Icons.quiz_outlined, tone: EmTileTone.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Check what you learned', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.primaryVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        );
      },
    );
  }
}

class _VideoLesson extends StatefulWidget {
  const _VideoLesson({required this.url});

  final String url;

  @override
  State<_VideoLesson> createState() => _VideoLessonState();
}

class _VideoLessonState extends State<_VideoLesson> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  late final Future<void> _initializing = _controller.initialize().then((_) {
    if (mounted) setState(() {});
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializing,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _MediaError();
        final ready = snapshot.connectionState == ConnectionState.done;
        final ratio = ready && _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 16 / 9;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: AppColors.textPrimary,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(aspectRatio: ratio, child: ready ? VideoPlayer(_controller) : const SizedBox.shrink()),
                if (!ready)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: _controller.value.isPlaying ? 'Pause video' : 'Play video',
                      iconSize: 32,
                      constraints: const BoxConstraints.tightFor(width: 64, height: 64),
                      color: AppColors.primary,
                      onPressed: _toggle,
                      icon: Icon(_controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                  ),
                if (ready)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      colors: const VideoProgressColors(
                          playedColor: Colors.white, bufferedColor: Colors.white38, backgroundColor: Colors.white24),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(18)),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.primary, size: 32),
          SizedBox(height: 8),
          Text('This media couldn’t be loaded.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: const [
          EmSkeleton(height: 196, radius: 18),
          SizedBox(height: 20),
          EmSkeleton(height: 12, width: 100),
          SizedBox(height: 10),
          EmSkeleton(height: 26),
          SizedBox(height: 20),
          EmSkeleton(height: 16),
          SizedBox(height: 8),
          EmSkeleton(height: 16),
          SizedBox(height: 8),
          EmSkeleton(height: 16, width: 220),
        ],
      ),
    );
  }
}
