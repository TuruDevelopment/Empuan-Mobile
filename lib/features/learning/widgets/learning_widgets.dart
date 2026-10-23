import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';

const learningDisclaimer =
    'General education only. For legal or money decisions, talk to a professional.';

/// Turns lesson or course HTML (or plain text) into readable paragraphs.
List<String> htmlToParagraphs(String? source) {
  if (source == null || source.trim().isEmpty) return const [];
  final text = source
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6]|ul|ol)>', caseSensitive: false), '\n')
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', '’');
  return text.split(RegExp(r'\n+')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
}

String minutesLabel(int seconds) => '${(seconds / 60).ceil().clamp(1, 600)} min';

String lessonTypeLabel(String type) => switch (type) {
      'video' => 'Video',
      'article' => 'Article',
      'infographic' => 'Infographic',
      'audio' => 'Audio',
      'text' || 'short' => 'Short lesson',
      _ => humanize(type),
    };

String difficultyLabel(String difficulty) => switch (difficulty) {
      'intermediate' => 'Intermediate',
      'advanced' => 'Advanced',
      _ => 'Beginner',
    };

String humanize(String value) {
  if (value.isEmpty) return value;
  final spaced = value.replaceAll('_', ' ');
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

/// "Ages 25–34" becomes "ages 25–34" so it reads inside a sentence.
String inSentence(String name) {
  if (name.length < 2 || name[1].toUpperCase() == name[1]) return name;
  return '${name[0].toLowerCase()}${name.substring(1)}';
}

LearningLessonSummary? nextLessonOf(LearningCourse course) {
  for (final lesson in course.lessons) {
    if (lesson.progress?.isCompleted != true) return lesson;
  }
  return null;
}

int completedLessonsOf(LearningCourse course) {
  final listed = course.lessons.where((l) => l.progress?.isCompleted == true).length;
  return listed > 0 ? listed : (course.enrollment?.completedLessons ?? 0);
}

bool isCourseComplete(LearningCourse course) {
  if ((course.enrollment?.progressPercent ?? 0) >= 100) return true;
  final lessons = course.lessons.toList();
  return course.isEnrolled && lessons.isNotEmpty && lessons.every((l) => l.progress?.isCompleted == true);
}

/// "4 lessons · 30 min · Certificate"
String courseMeta(LearningCourse course, {LearningProgressSummary? progress}) {
  final count = course.lessonCount;
  final summary = progress ?? course.enrollment;
  final parts = <String>[
    if (count > 0) '$count ${count == 1 ? 'lesson' : 'lessons'}',
    if (course.estimatedMinutes > 0) '${course.estimatedMinutes} min',
  ];
  if (summary != null && summary.progressPercent >= 100) {
    parts.add('Completed');
  } else if (course.isEnrolled || summary != null) {
    parts.add('In progress');
  } else if (course.certificateEnabled) {
    parts.add('Certificate');
  }
  return parts.join(' · ');
}

/// Network image with a blush placeholder when there is no image or it fails.
class LearningThumb extends StatelessWidget {
  const LearningThumb({super.key, this.url, this.width, this.height, this.radius = 14});

  final String? url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.blush,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: AppColors.secondary, size: 28),
    );
    final link = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: link == null || link.isEmpty
          ? placeholder
          : Image.network(
              link,
              width: width,
              height: height,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Course card used on the Learn tab, catalog and search results.
class LearningCourseRow extends StatelessWidget {
  const LearningCourseRow({super.key, required this.course, required this.onTap});

  final LearningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = courseMeta(course);
    return EmCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          LearningThumb(url: course.thumbnailUrl, width: 88, height: 88),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.category != null) ...[EmTag(course.category!.name), const SizedBox(height: 6)],
                Text(course.title, style: Theme.of(context).textTheme.titleSmall),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta, style: const TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson count progress bar with "x of y lessons".
class LearningProgressLine extends StatelessWidget {
  const LearningProgressLine({super.key, required this.done, required this.total, this.short = false});

  final int done;
  final int total;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final label = short ? '$done of $total' : '$done of $total lessons';
    return Semantics(
      label: '$done of $total lessons done',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(child: EmProgressBar(value: total == 0 ? 0 : done / total)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Small square showing an icon or letter, used for quiz answer keys.
class LearningKeyBadge extends StatelessWidget {
  const LearningKeyBadge(this.label, {super.key, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.blush,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.primary),
      ),
    );
  }
}

/// Top bar with a close button, a centred caption and a progress bar.
class LearningProgressTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LearningProgressTopBar({
    super.key,
    required this.closeLabel,
    required this.onClose,
    this.caption,
    this.progress,
  });

  final String closeLabel;
  final VoidCallback onClose;
  final String? caption;
  final double? progress;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 8),
              EmIconButton(icon: Icons.close_rounded, label: closeLabel, onPressed: onClose),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (caption != null)
                        Text(
                          caption!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      if (progress != null) ...[const SizedBox(height: 6), EmProgressBar(value: progress!)],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable wrapper so state views still support pull-to-refresh.
class LearningScrollableState extends StatelessWidget {
  const LearningScrollableState({super.key, required this.child, required this.onRefresh});

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Tappable source link shared by course and lesson screens.
class LearningSourceRow extends StatelessWidget {
  const LearningSourceRow({super.key, required this.source});

  final LearningSource source;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source.url);
    final canOpen = uri != null && uri.hasScheme;
    return EmCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: canOpen
          ? () async {
              final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!opened && context.mounted) showEmToast(context, 'Couldn’t open this link.');
            }
          : null,
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.title.isEmpty ? source.url : source.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (source.publisher != null && source.publisher!.isNotEmpty)
                  Text(source.publisher!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (canOpen) const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.quietIcon),
        ],
      ),
    );
  }
}
