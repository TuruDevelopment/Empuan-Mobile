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

  Future<void> _reload() async {
    final future = _service.getCourse(widget.slug);
    setState(() => _courseFuture = future);
    await future;
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
        final course = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final topInset = MediaQuery.of(context).padding.top;

        Widget body;
        if (loading) {
          body = const EmLoading();
        } else if (snapshot.hasError) {
          body = LearningScrollableState(
            onRefresh: _reload,
            child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
          );
        } else {
          body = _CourseContent(
            course: course!,
            onRefresh: _reload,
            onOpenLesson: (lesson) => _openLesson(course, lesson),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned.fill(
                child: loading || snapshot.hasError ? Padding(padding: EdgeInsets.only(top: topInset + 60), child: body) : body,
              ),
              Positioned(
                top: topInset + 8,
                left: 12,
                child: EmIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: 'Back',
                  style: EmIconButtonStyle.soft,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: course == null || loading || snapshot.hasError
              ? null
              : EmBottomBar(child: _cta(course)),
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
    return EmButton(
      label: '${started ? 'Continue' : 'Start'}: ${next.title}',
      onPressed: () => _openLesson(course, next),
    );
  }
}

class _CourseContent extends StatelessWidget {
  const _CourseContent({required this.course, required this.onRefresh, required this.onOpenLesson});

  final LearningCourse course;
  final Future<void> Function() onRefresh;
  final ValueChanged<LearningLessonSummary> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final about = htmlToParagraphs(course.description?.trim().isNotEmpty == true ? course.description : course.summary);
    final total = course.lessonCount;
    final current = course.isEnrolled ? nextLessonOf(course) : null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: MediaQuery.of(context).padding.top,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 240 + MediaQuery.of(context).padding.top,
            child: LearningThumb(url: course.thumbnailUrl, radius: 0, width: double.infinity, height: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.category != null) ...[EmTag(course.category!.name), const SizedBox(height: 8)],
                Text(course.title, style: text.headlineLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (course.estimatedMinutes > 0) _Fact(icon: Icons.schedule_rounded, label: '${course.estimatedMinutes} min'),
                    _Fact(icon: Icons.signal_cellular_alt_rounded, label: difficultyLabel(course.difficulty)),
                    if (course.certificateEnabled) const _Fact(icon: Icons.workspace_premium_outlined, label: 'Certificate'),
                  ],
                ),
                if (course.isEnrolled && total > 0) ...[
                  const SizedBox(height: 20),
                  EmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        LearningProgressLine(done: completedLessonsOf(course), total: total),
                      ],
                    ),
                  ),
                ],
                if (about.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('About this course', style: text.titleMedium),
                  const SizedBox(height: 8),
                  for (final paragraph in about)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(paragraph, style: text.bodyMedium),
                    ),
                ],
                if (course.learningOutcomes.isNotEmpty) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Lessons', style: text.titleMedium)),
                    if (total > 0) Text('$total ${total == 1 ? 'lesson' : 'lessons'}', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                if (course.sections.isEmpty)
                  Text('Lessons for this course haven’t been published yet.', style: text.bodySmall)
                else
                  ..._sections(context, current),
                if (course.sources.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Sources', style: text.titleMedium),
                  const SizedBox(height: 10),
                  for (final source in course.sources)
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: LearningSourceRow(source: source)),
                ],
              ],
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
      status = const _StatusCircle(fill: AppColors.primary, child: Icon(Icons.check_rounded, size: 16, color: Colors.white));
    } else if (isCurrent) {
      status = const _StatusCircle(
        fill: Colors.white,
        border: AppColors.primary,
        child: Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.primary),
      );
    } else {
      status = _StatusCircle(
        border: AppColors.line2,
        child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
