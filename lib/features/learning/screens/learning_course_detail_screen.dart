import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_certificate_screen.dart';
import 'package:Empuan/features/learning/screens/learning_lesson_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';

class LearningCourseDetailScreen extends StatefulWidget {
  const LearningCourseDetailScreen({
    super.key,
    required this.slug,
    required this.service,
  });

  final String slug;
  final LearningService service;

  @override
  State<LearningCourseDetailScreen> createState() =>
      _LearningCourseDetailScreenState();
}

class _LearningCourseDetailScreenState
    extends State<LearningCourseDetailScreen> {
  late Future<LearningCourse> _courseFuture;
  bool _enrolling = false;

  @override
  void initState() {
    super.initState();
    _courseFuture = widget.service.getCourse(widget.slug);
  }

  Future<void> _reload() async {
    setState(() => _courseFuture = widget.service.getCourse(widget.slug));
    await _courseFuture;
  }

  Future<void> _enroll() async {
    setState(() => _enrolling = true);

    try {
      await widget.service.enroll(widget.slug);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil terdaftar pada course.')),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  void _openLesson(
    LearningCourse course,
    LearningLessonSummary lesson,
  ) {
    final canOpen = course.isEnrolled || lesson.isPreview;

    if (!canOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar ke course untuk membuka materi ini.'),
        ),
      );
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LearningLessonScreen(
              lessonId: lesson.id,
              service: widget.service,
              canTrackProgress: course.isEnrolled,
            ),
          ),
        )
        .then((_) => _reload());
  }

  void _continueCourse(LearningCourse course) {
    final lessons = course.lessons.toList();
    if (lessons.isEmpty) return;

    final next = lessons.cast<LearningLessonSummary?>().firstWhere(
          (lesson) => lesson?.progress?.isCompleted != true,
          orElse: () => lessons.first,
        );
    if (next != null) _openLesson(course, next);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningCourse>(
      future: _courseFuture,
      builder: (context, snapshot) {
        final course = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(course?.title ?? 'Detail Course'),
          ),
          bottomNavigationBar: course == null
              ? null
              : _CourseActionBar(
                  course: course,
                  enrolling: _enrolling,
                  onEnroll: _enroll,
                  onContinue: () => _continueCourse(course),
                ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (snapshot.hasError) {
                return LearningErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }

              return _CourseContent(
                course: snapshot.requireData,
                onRefresh: _reload,
                onOpenLesson: (lesson) =>
                    _openLesson(snapshot.requireData, lesson),
                onOpenCertificate: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LearningCertificateScreen(
                        courseSlug: snapshot.requireData.slug,
                        service: widget.service,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CourseContent extends StatelessWidget {
  const _CourseContent({
    required this.course,
    required this.onRefresh,
    required this.onOpenLesson,
    required this.onOpenCertificate,
  });

  final LearningCourse course;
  final Future<void> Function() onRefresh;
  final ValueChanged<LearningLessonSummary> onOpenLesson;
  final VoidCallback onOpenCertificate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          _CourseHeader(course: course),
          if (course.certificateEnabled &&
              (course.enrollment?.progressPercent ?? 0) >= 100) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onOpenCertificate,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Lihat sertifikat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const LearningSectionTitle(title: 'Tentang course'),
          const SizedBox(height: 10),
          SelectableText(
            _plainText(course.description ?? course.summary),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
          ),
          if (course.learningOutcomes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const LearningSectionTitle(title: 'Yang akan dipelajari'),
            const SizedBox(height: 12),
            ...course.learningOutcomes.map(
              (outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 21,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        outcome,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          LearningSectionTitle(
            title: 'Daftar materi',
            subtitle: '${course.lessons.length} materi',
          ),
          const SizedBox(height: 12),
          if (course.sections.isEmpty)
            const LearningEmptyState(
              title: 'Materi belum tersedia',
              message: 'Admin masih menyiapkan isi course ini.',
            )
          else
            ...course.sections.asMap().entries.map(
                  (entry) => _SectionCard(
                    index: entry.key + 1,
                    section: entry.value,
                    enrolled: course.isEnrolled,
                    onOpenLesson: onOpenLesson,
                  ),
                ),
          if (course.sources.isNotEmpty) ...[
            const SizedBox(height: 24),
            const LearningSectionTitle(title: 'Sumber materi'),
            const SizedBox(height: 10),
            ...course.sources.map(
              (source) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                ),
                title: Text(source.title),
                subtitle:
                    source.publisher == null ? null : Text(source.publisher!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                course.category!.name,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            course.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.summary,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              height: 1.55,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _HeaderFact(
                icon: Icons.schedule_outlined,
                label: '${course.estimatedMinutes} menit',
              ),
              _HeaderFact(
                icon: Icons.signal_cellular_alt_rounded,
                label: _difficultyLabel(course.difficulty),
              ),
              if (course.certificateEnabled)
                const _HeaderFact(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Sertifikat',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  const _HeaderFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.index,
    required this.section,
    required this.enrolled,
    required this.onOpenLesson,
  });

  final int index;
  final LearningSection section;
  final bool enrolled;
  final ValueChanged<LearningLessonSummary> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.6),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: index == 1,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.35),
          foregroundColor: AppColors.primary,
          child: Text('$index'),
        ),
        title: Text(
          section.title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text('${section.lessons.length} materi'),
        children: section.lessons.map((lesson) {
          final unlocked = enrolled || lesson.isPreview;
          final completed = lesson.progress?.isCompleted == true;

          return Semantics(
            button: unlocked,
            enabled: unlocked,
            label: unlocked
                ? 'Buka materi ${lesson.title}'
                : 'Materi ${lesson.title} terkunci',
            child: ListTile(
              onTap: unlocked ? () => onOpenLesson(lesson) : null,
              minVerticalPadding: 12,
              leading: Icon(
                completed
                    ? Icons.check_circle_rounded
                    : unlocked
                        ? _lessonIcon(lesson.type)
                        : Icons.lock_outline_rounded,
                color: completed
                    ? AppColors.secondary
                    : unlocked
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                [
                  _lessonTypeLabel(lesson.type),
                  if (lesson.durationSeconds > 0)
                    _durationLabel(lesson.durationSeconds),
                  if (lesson.isPreview) 'Preview',
                ].join(' • '),
              ),
              trailing:
                  unlocked ? const Icon(Icons.chevron_right_rounded) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CourseActionBar extends StatelessWidget {
  const _CourseActionBar({
    required this.course,
    required this.enrolling,
    required this.onEnroll,
    required this.onContinue,
  });

  final LearningCourse course;
  final bool enrolling;
  final VoidCallback onEnroll;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: FilledButton.icon(
          onPressed: enrolling || course.lessons.isEmpty
              ? null
              : course.isEnrolled
                  ? onContinue
                  : onEnroll,
          icon: enrolling
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  course.isEnrolled
                      ? Icons.play_arrow_rounded
                      : Icons.add_rounded,
                ),
          label: Text(
            enrolling
                ? 'Mendaftarkan...'
                : course.isEnrolled
                    ? 'Lanjutkan belajar'
                    : 'Daftar course',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

IconData _lessonIcon(String type) {
  return switch (type) {
    'video' => Icons.play_circle_outline_rounded,
    'infographic' => Icons.image_outlined,
    'case_study' => Icons.fact_check_outlined,
    'simulation' => Icons.touch_app_outlined,
    _ => Icons.article_outlined,
  };
}

String _lessonTypeLabel(String type) {
  return switch (type) {
    'video' => 'Video',
    'microlearning' => 'Microlearning',
    'infographic' => 'Infografis',
    'case_study' => 'Studi kasus',
    'simulation' => 'Simulasi',
    _ => 'Artikel',
  };
}

String _difficultyLabel(String difficulty) {
  return switch (difficulty) {
    'advanced' => 'Lanjutan',
    'intermediate' => 'Menengah',
    _ => 'Pemula',
  };
}

String _durationLabel(int seconds) {
  final minutes = (seconds / 60).ceil();
  return '$minutes menit';
}

String _plainText(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</li>|</h[1-6]>', caseSensitive: false), '\n')
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();
}
