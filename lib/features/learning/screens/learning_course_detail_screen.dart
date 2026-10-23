import 'package:flutter/material.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';
import 'learning_certificate_screen.dart';
import 'learning_lesson_screen.dart';

class LearningCourseDetailScreen extends StatefulWidget {
  const LearningCourseDetailScreen({super.key, required this.slug, this.service});

  final String slug;
  final LearningService? service;

  @override
  State<LearningCourseDetailScreen> createState() => _LearningCourseDetailScreenState();
}

class _LearningCourseDetailScreenState extends State<LearningCourseDetailScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  late Future<LearningCourse> _courseFuture = _service.getCourse(widget.slug);
  bool _enrolling = false;
  final _entrance = LearningEntrance();

  Future<void> _reload() async {
    final future = _service.getCourse(widget.slug);
    setState(() {
      _courseFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      await _service.enroll(widget.slug);
      if (!mounted) return;
      showEmToast(context, 'You’re enrolled. Your progress will be saved.', icon: Icons.check_rounded);
      await _reload();
    } catch (error) {
      if (mounted) showEmToast(context, '$error');
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _openLesson(LearningCourse course, LearningLessonSummary lesson) async {
    if (!course.isEnrolled && !lesson.isPreview) {
      showEmToast(context, 'Enroll in this course to open this lesson.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningLessonScreen(
          lessonId: lesson.id,
          service: _service,
          canTrackProgress: course.isEnrolled,
          course: course,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  void _openCertificate(LearningCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LearningCertificateScreen(courseSlug: course.slug, service: _service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningCourse>(
      future: _courseFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final course = loading ? null : snapshot.data;

        final String key;
        final Widget body;
        if (loading) {
          key = 'loading';
          body = const _BackScaffoldBody(child: _DetailSkeleton());
        } else if (snapshot.hasError) {
          key = 'error';
          body = _BackScaffoldBody(
            child: LearningScrollableState(
              onRefresh: _reload,
              child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
            ),
          );
        } else {
          key = 'content';
          body = _CourseContent(
            course: course!,
            entrance: _entrance,
            onRefresh: _reload,
            onOpenLesson: (lesson) => _openLesson(course, lesson),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: EmStateSwitcher(stateKey: key, child: body),
          bottomNavigationBar:
              course == null || snapshot.hasError ? null : EmFadeSlideIn(child: EmBottomBar(child: _cta(course))),
        );
      },
    );
  }

  Widget _cta(LearningCourse course) {
    if (!course.isEnrolled) {
      return EmButton(label: 'Enroll', loading: _enrolling, onPressed: _enroll);
    }
    final lessons = course.lessons.toList();
    if (isCourseComplete(course)) {
      if (course.certificateEnabled) {
        return EmButton(
          label: 'View certificate',
          icon: Icons.workspace_premium_outlined,
          onPressed: () => _openCertificate(course),
        );
      }
      return EmButton(
        label: 'Review the first lesson',
        variant: EmButtonVariant.secondary,
        onPressed: lessons.isEmpty ? null : () => _openLesson(course, lessons.first),
      );
    }
    final next = nextLessonOf(course);
    if (next == null) return const EmButton(label: 'No lessons yet');
    final started = completedLessonsOf(course) > 0;
    final label = '${started ? 'Continue' : 'Start'}: ${next.title}';
    return EmAnimatedSwap(
      valueKey: label,
      child: EmButton(label: label, onPressed: () => _openLesson(course, next)),
    );
  }
}

class _CourseContent extends StatelessWidget {
  const _CourseContent(
      {required this.course, required this.entrance, required this.onRefresh, required this.onOpenLesson});

  final LearningCourse course;
  final LearningEntrance entrance;
  final Future<void> Function() onRefresh;
  final ValueChanged<LearningLessonSummary> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final about = htmlToParagraphs(course.description?.trim().isNotEmpty == true ? course.description : course.summary);
    final total = course.lessonCount;
    final current = course.isEnrolled ? nextLessonOf(course) : null;
    final top = MediaQuery.of(context).padding.top;

    final children = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.category != null) ...[EmTag(course.category!.name), const SizedBox(height: 8)],
          Text(course.title, style: text.headlineLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (course.estimatedMinutes > 0)
                _Fact(icon: Icons.schedule_rounded, label: '${course.estimatedMinutes} min'),
              _Fact(icon: Icons.signal_cellular_alt_rounded, label: difficultyLabel(course.difficulty)),
              if (course.certificateEnabled) const _Fact(icon: Icons.workspace_premium_outlined, label: 'Certificate'),
            ],
          ),
        ],
      ),
      if (course.isEnrolled && total > 0)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: EmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                LearningProgressLine(done: completedLessonsOf(course), total: total),
              ],
            ),
          ),
        ),
      if (about.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About this course', style: text.titleMedium),
              const SizedBox(height: 8),
              for (final paragraph in about)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(paragraph, style: text.bodyMedium)),
            ],
          ),
        ),
      if (course.learningOutcomes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You’ll learn to', style: text.titleMedium),
              const SizedBox(height: 10),
              for (final outcome in course.learningOutcomes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(outcome, style: text.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text('Lessons', style: text.titleMedium)),
            if (total > 0) Text('$total ${total == 1 ? 'lesson' : 'lessons'}', style: text.bodySmall),
          ],
        ),
      ),
      if (course.sections.isEmpty)
        Text('Lessons for this course haven’t been published yet.', style: text.bodySmall)
      else
        ..._sections(context, current),
      if (course.sources.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sources', style: text.titleMedium),
              const SizedBox(height: 10),
              for (final source in course.sources)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: LearningSourceRow(source: source)),
            ],
          ),
        ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: top + kToolbarHeight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: EmIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: 'Back',
                  style: EmIconButtonStyle.soft,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, box) {
                final minHeight = top + kToolbarHeight;
                final expanded = (box.maxHeight - minHeight) / (240 + top - minHeight);
                // The title fades in only as the image finishes collapsing.
                final titleOpacity = (1 - expanded.clamp(0.0, 1.0) / 0.2).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: LearningThumb(
                          url: course.thumbnailUrl, radius: 0, width: double.infinity, height: double.infinity),
                    ),
                    Positioned(
                      left: 76,
                      right: 20,
                      bottom: 0,
                      height: kToolbarHeight,
                      child: ExcludeSemantics(
                        excluding: titleOpacity == 0,
                        child: Opacity(
                          opacity: titleOpacity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(course.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => entrance.wrap(i, children[i]),
                childCount: children.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context, LearningLessonSummary? current) {
    var number = 0;
    final widgets = <Widget>[];
    for (var s = 0; s < course.sections.length; s++) {
      final section = course.sections[s];
      if (section.lessons.isEmpty) continue;
      widgets.add(EmCaption('${s + 1} · ${section.title}'));
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        EmGroup(
          children: [
            for (final lesson in section.lessons)
              _LessonRow(
                number: ++number,
                lesson: lesson,
                isCurrent: current?.id == lesson.id,
                locked: !course.isEnrolled && !lesson.isPreview,
                onTap: () => onOpenLesson(lesson),
              ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.number,
    required this.lesson,
    required this.isCurrent,
    required this.locked,
    required this.onTap,
  });

  final int number;
  final LearningLessonSummary lesson;
  final bool isCurrent;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = lesson.progress?.isCompleted == true;
    final meta = [
      lessonTypeLabel(lesson.type),
      if (lesson.durationSeconds > 0) minutesLabel(lesson.durationSeconds),
      if (lesson.hasQuiz) 'Quiz',
      if (done) 'Done' else if (locked) 'Enroll to open' else if (lesson.isPreview) 'Preview',
    ].join(' · ');

    final Widget status;
    if (done) {
      status =
          const _StatusCircle(fill: AppColors.primary, child: Icon(Icons.check_rounded, size: 16, color: Colors.white));
    } else if (isCurrent) {
      status = const _StatusCircle(
        fill: Colors.white,
        border: AppColors.primary,
        child: Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.primary),
      );
    } else {
      status = _StatusCircle(
        border: AppColors.line2,
        child: Text('$number',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      );
    }

    return EmRow(
      title: lesson.title,
      subtitle: meta,
      leading: status,
      highlighted: isCurrent,
      onTap: onTap,
      trailing: locked ? const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.quietIcon) : null,
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.child, this.fill, this.border});

  final Widget child;
  final Color? fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      child: child,
    );
  }
}

/// Back button above a non-content state, since there's no header image yet.
class _BackScaffoldBody extends StatelessWidget {
  const _BackScaffoldBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EmTopBar(),
        Expanded(child: child),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const EmSkeleton(height: 180, radius: 20),
          const SizedBox(height: 20),
          const EmSkeleton(height: 20, width: 72, radius: 10),
          const SizedBox(height: 12),
          const EmSkeleton(height: 28),
          const SizedBox(height: 10),
          const EmSkeleton(height: 14, width: 200),
          const SizedBox(height: 28),
          for (var i = 0; i < 3; i++) ...[
            const Row(
              children: [
                EmSkeleton(width: 30, height: 30, radius: 15),
                SizedBox(width: 14),
                Expanded(child: EmSkeleton(height: 16)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
