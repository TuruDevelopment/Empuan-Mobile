import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_quiz_screen.dart';
import 'package:Empuan/features/learning/services/learning_progress_sync_service.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class LearningLessonScreen extends StatefulWidget {
  const LearningLessonScreen({
    super.key,
    required this.lessonId,
    required this.service,
    required this.canTrackProgress,
  });

  final int lessonId;
  final LearningService service;
  final bool canTrackProgress;

  @override
  State<LearningLessonScreen> createState() => _LearningLessonScreenState();
}

class _LearningLessonScreenState extends State<LearningLessonScreen> {
  late Future<LearningLesson> _lessonFuture;
  bool _saving = false;
  bool _completed = false;
  late final LearningProgressSyncService _progressSync;

  @override
  void initState() {
    super.initState();
    _progressSync = LearningProgressSyncService(widget.service);
    _lessonFuture = widget.service.getLesson(widget.lessonId);
  }

  Future<void> _reload() async {
    setState(() => _lessonFuture = widget.service.getLesson(widget.lessonId));
    await _lessonFuture;
  }

  Future<void> _markCompleted() async {
    setState(() => _saving = true);

    try {
      final result = await _progressSync.completeLesson(widget.lessonId);
      if (!mounted) return;
      setState(() => _completed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.synced
                ? 'Materi ditandai selesai.'
                : 'Progres disimpan dan akan disinkronkan saat online.',
          ),
        ),
      );
      if (result.synced) await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningLesson>(
      future: _lessonFuture,
      builder: (context, snapshot) {
        final lesson = snapshot.data;
        final completed = _completed || lesson?.progress?.isCompleted == true;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(lesson?.title ?? 'Materi')),
          bottomNavigationBar: lesson == null || !widget.canTrackProgress
              ? null
              : Material(
                  elevation: 12,
                  color: AppColors.surface,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: FilledButton.icon(
                      onPressed: _saving || completed ? null : _markCompleted,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              completed
                                  ? Icons.check_circle_rounded
                                  : Icons.check_rounded,
                            ),
                      label: Text(
                        completed ? 'Materi selesai' : 'Tandai selesai',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
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

              return _LessonContent(
                lesson: snapshot.requireData,
                canTrackProgress: widget.canTrackProgress,
                onQuizCompleted: _reload,
                service: widget.service,
              );
            },
          ),
        );
      },
    );
  }
}

class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.lesson,
    required this.canTrackProgress,
    required this.onQuizCompleted,
    required this.service,
  });

  final LearningLesson lesson;
  final bool canTrackProgress;
  final Future<void> Function() onQuizCompleted;
  final LearningService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          lesson.sectionTitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lesson.title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 25,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (lesson.summary != null && lesson.summary!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            lesson.summary!,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (lesson.isPreview) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ini adalah materi preview.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (lesson.type == 'video' &&
            lesson.mediaUrl != null &&
            lesson.mediaUrl!.isNotEmpty)
          _VideoLesson(url: lesson.mediaUrl!)
        else if (lesson.type == 'infographic' &&
            lesson.mediaUrl != null &&
            lesson.mediaUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              lesson.mediaUrl!,
              fit: BoxFit.contain,
              semanticLabel: 'Infografis ${lesson.title}',
              errorBuilder: (_, __, ___) => const _MediaError(),
            ),
          ),
        if (lesson.body != null && lesson.body!.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          SelectableText(
            _plainText(lesson.body!),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (lesson.content != null && lesson.content!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...lesson.content!.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _humanize(entry.key),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _structuredValue(entry.value),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (lesson.hasQuiz && canTrackProgress) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final passed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LearningQuizScreen(
                    lessonId: lesson.id,
                    service: service,
                  ),
                ),
              );
              if (passed == true) await onQuizCompleted();
            },
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Kerjakan kuis'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
        if (lesson.sources.isNotEmpty) ...[
          const SizedBox(height: 26),
          const LearningSectionTitle(title: 'Sumber'),
          const SizedBox(height: 8),
          ...lesson.sources.map(
            (source) => ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              leading: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
              ),
              title: Text(source.title),
              subtitle:
                  source.publisher == null ? null : Text(source.publisher!),
              onTap: source.url.isEmpty
                  ? null
                  : () => launchUrl(
                        Uri.parse(source.url),
                        mode: LaunchMode.externalApplication,
                      ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Materi ini bersifat edukasi umum. Gunakan sumber profesional '
            'yang sesuai untuk keputusan medis, hukum, atau keuangan.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
  late final VideoPlayerController _controller;
  late final Future<void> _initializing;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initializing = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializing,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _MediaError();
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  colors: const VideoProgressColors(
                    playedColor: AppColors.highlight,
                    bufferedColor: AppColors.textSecondary,
                  ),
                ),
                Semantics(
                  button: true,
                  label: _controller.value.isPlaying
                      ? 'Jeda video'
                      : 'Putar video',
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    color: Colors.white,
                    iconSize: 34,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                    ),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppColors.primary,
            size: 36,
          ),
          SizedBox(height: 8),
          Text('Media tidak dapat dimuat'),
        ],
      ),
    );
  }
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

String _humanize(String value) {
  if (value.isEmpty) return value;
  final spaced = value.replaceAll('_', ' ');
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _structuredValue(dynamic value) {
  if (value is List) return value.map((item) => '• $item').join('\n');
  if (value is Map) {
    return value.entries
        .map((entry) => '${_humanize(entry.key.toString())}: ${entry.value}')
        .join('\n');
  }
  return value?.toString() ?? '';
}
