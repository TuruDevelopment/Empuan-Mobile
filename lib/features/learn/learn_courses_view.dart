import 'dart:async';

import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';
import '../learning/models/learning_models.dart';
import '../learning/screens/learning_catalog_screen.dart';
import '../learning/screens/learning_course_detail_screen.dart';
import '../learning/screens/learning_lesson_screen.dart';
import '../learning/services/learning_progress_sync_service.dart';
import '../learning/services/learning_service.dart';
import '../learning/widgets/learning_widgets.dart';

/// Courses segment of the Learn tab: continue, topics and picked courses,
/// or the date of birth gate for accounts created before it was required.
class LearnCoursesView extends StatefulWidget {
  const LearnCoursesView({super.key, required this.service});

  final LearningService service;

  @override
  State<LearnCoursesView> createState() => _LearnCoursesViewState();
}

class _LearnCoursesViewState extends State<LearnCoursesView> {
  late Future<LearningHomeData> _homeFuture;

  LearningService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    unawaited(LearningProgressSyncService(_service).syncPending());
    _homeFuture = _service.getHome();
  }

  Future<void> _reload() async {
    final future = _service.getHome();
    setState(() => _homeFuture = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  Future<void> _open(Widget screen) async {
    await pushScreen<void>(context, screen);
    if (mounted) await _reload();
  }

  void _openCatalog({String? category, bool search = false}) =>
      _open(LearningCatalogScreen(service: _service, initialCategory: category, autofocus: search));

  void _openCourse(LearningCourse course) => _open(LearningCourseDetailScreen(slug: course.slug, service: _service));

  void _continue(LearningEnrollment enrollment) {
    final course = enrollment.course;
    final next = nextLessonOf(course);
    if (next == null) {
      _openCourse(course);
    } else {
      _open(LearningLessonScreen(lessonId: next.id, service: _service, canTrackProgress: true, course: course));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningHomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const EmLoading();
        final error = snapshot.error;
        if (error is LearningApiException && error.requiresDateOfBirth) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [_DobGate(service: _service, onSaved: _reload)],
          );
        }
        if (error != null) {
          final blocked = error is LearningApiException && error.statusCode == 403;
          return LearningScrollableState(
            onRefresh: _reload,
            child: blocked
                ? EmStateView(
                    icon: Icons.lock_outline_rounded,
                    title: 'Courses aren’t available on your account',
                    message: '$error',
                  )
                : EmStateView.error(message: '$error', onRetry: _reload),
          );
        }
        return _HomeContent(
          data: snapshot.requireData,
          onRefresh: _reload,
          onSearch: () => _openCatalog(search: true),
          onTopic: (code) => _openCatalog(category: code),
          onAllTopics: () => _openCatalog(),
          onCourse: _openCourse,
          onContinue: _continue,
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.data,
    required this.onRefresh,
    required this.onSearch,
    required this.onTopic,
    required this.onAllTopics,
    required this.onCourse,
    required this.onContinue,
  });

  final LearningHomeData data;
  final Future<void> Function() onRefresh;
  final VoidCallback onSearch;
  final ValueChanged<String> onTopic;
  final VoidCallback onAllTopics;
  final ValueChanged<LearningCourse> onCourse;
  final ValueChanged<LearningEnrollment> onContinue;

  @override
  Widget build(BuildContext context) {
    final stage = data.lifeStage;
    final inProgress = data.continueLearning.where((e) => e.summary.progressPercent < 100).toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          _SearchButton(onTap: onSearch),
          if (inProgress.isNotEmpty) ...[
            const SizedBox(height: 20),
            const EmSectionHeader('Continue'),
            const SizedBox(height: 10),
            for (final enrollment in inProgress)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContinueCard(enrollment: enrollment, onTap: () => onContinue(enrollment)),
              ),
          ],
          if (data.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            EmSectionHeader('Topics', actionLabel: 'All', onAction: onAllTopics),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in data.categories)
                  EmChip(label: category.name, selected: false, onTap: () => onTopic(category.code)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          EmSectionHeader(stage == null || stage.name.isEmpty ? 'Recommended' : 'Picked for ${inSentence(stage.name)}'),
          const SizedBox(height: 10),
          if (data.recommendedCourses.isEmpty)
            EmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No picks for you yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('New courses are added regularly. You can still browse everything.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  EmButton(label: 'Browse courses', variant: EmButtonVariant.tonal, small: true, expand: false, onPressed: onAllTopics),
                ],
              ),
            )
          else
            for (final course in data.recommendedCourses)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LearningCourseRow(course: course, onTap: () => onCourse(course)),
              ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(learningDisclaimer, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search courses',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line2, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: const SizedBox(
            height: 52,
            child: Row(
              children: [
                SizedBox(width: 14),
                Icon(Icons.search_rounded, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Search courses', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.enrollment, required this.onTap});

  final LearningEnrollment enrollment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course;
    final summary = enrollment.summary;
    final next = nextLessonOf(course);
    final nextLine = next == null
        ? null
        : 'Next: ${next.title}${next.durationSeconds > 0 ? ' · ${minutesLabel(next.durationSeconds)}' : ''}';
    return EmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LearningThumb(url: course.thumbnailUrl, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: Theme.of(context).textTheme.titleSmall),
                    if (nextLine != null) ...[
                      const SizedBox(height: 4),
                      Text(nextLine, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (summary.totalLessons > 0) ...[
            const SizedBox(height: 12),
            LearningProgressLine(done: summary.completedLessons, total: summary.totalLessons),
          ],
        ],
      ),
    );
  }
}

class _DobGate extends StatefulWidget {
  const _DobGate({required this.service, required this.onSaved});

  final LearningService service;
  final Future<void> Function() onSaved;

  @override
  State<_DobGate> createState() => _DobGateState();
}

class _DobGateState extends State<_DobGate> {
  final _field = TextEditingController();
  DateTime? _dob;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  static bool isAdult(DateTime dob, DateTime today) {
    final eighteenth = DateTime(dob.year + 18, dob.month, dob.day);
    return !eighteenth.isAfter(DateTime(today.year, today.month, today.day));
  }

  Future<void> _pick() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(today.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Date of birth',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dob = picked;
      _field.text = formatDate(picked);
      _error = isAdult(picked, today) ? null : 'You need to be 18 or older to use courses.';
    });
  }

  Future<void> _save() async {
    final dob = _dob;
    if (dob == null) {
      setState(() => _error = 'Choose your date of birth.');
      return;
    }
    if (!isAdult(dob, DateTime.now())) {
      setState(() => _error = 'You need to be 18 or older to use courses.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateDateOfBirth(dob);
      if (!mounted) return;
      await widget.onSaved();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmIconTile(Icons.cake_outlined, size: 52),
          const SizedBox(height: 16),
          Text('Add your date of birth', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Your account was created before we asked for it. We use it to confirm you’re 18 or older '
            'and to pick courses for your stage of life. We never show it to anyone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Date of birth',
            controller: _field,
            hint: 'Choose a date',
            readOnly: true,
            onTap: _pick,
            suffixIcon: Icons.calendar_today_rounded,
            errorText: _error,
          ),
          const SizedBox(height: 16),
          EmButton(label: 'Save and show courses', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
