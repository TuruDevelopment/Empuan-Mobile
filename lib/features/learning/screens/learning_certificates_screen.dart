import 'package:flutter/material.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';
import 'learning_certificate_screen.dart';
import 'learning_course_detail_screen.dart';

typedef _CertificatesData = ({List<LearningCertificate> earned, List<LearningEnrollment> inProgress});

/// Earned certificates plus courses that are still in progress.
class LearningCertificatesScreen extends StatefulWidget {
  const LearningCertificatesScreen({super.key, this.service});

  final LearningService? service;

  @override
  State<LearningCertificatesScreen> createState() => _LearningCertificatesScreenState();
}

class _LearningCertificatesScreenState extends State<LearningCertificatesScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  late Future<_CertificatesData> _future = _load();

  Future<_CertificatesData> _load() async {
    final homeFuture = _service.getHome().then<List<LearningEnrollment>>(
          (home) => home.continueLearning.where((e) => e.summary.progressPercent < 100).toList(),
          // In-progress courses are extra; the list still works without them.
          onError: (Object _) => const <LearningEnrollment>[],
        );
    final earned = await _service.getCertificates();
    return (earned: earned, inProgress: await homeFuture);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EmTopBar(title: 'My certificates'),
      body: FutureBuilder<_CertificatesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const EmLoading();
          if (snapshot.hasError) {
            return LearningScrollableState(
              onRefresh: _reload,
              child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
            );
          }
          final data = snapshot.requireData;
          if (data.earned.isEmpty && data.inProgress.isEmpty) {
            return LearningScrollableState(
              onRefresh: _reload,
              child: const EmStateView(
                icon: Icons.workspace_premium_outlined,
                title: 'No certificates yet',
                message: 'Finish every lesson and quiz in a course to get its certificate.',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (data.earned.isEmpty)
                  Text('No certificates yet.', style: Theme.of(context).textTheme.bodySmall)
                else
                  EmGroup(
                    children: [
                      for (final certificate in data.earned)
                        EmRow(
                          leading: const EmIconTile(Icons.workspace_premium_rounded, tone: EmTileTone.primary),
                          title: certificate.courseTitle,
                          subtitle: certificate.issuedAt == null ? null : 'Issued ${formatDate(certificate.issuedAt!.toLocal())}',
                          onTap: () => _open(
                            LearningCertificateScreen(
                              courseSlug: certificate.courseSlug,
                              service: _service,
                              certificate: certificate,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (data.inProgress.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const EmCaption('In progress'),
                  const SizedBox(height: 8),
                  EmGroup(
                    children: [
                      for (final enrollment in data.inProgress)
                        _InProgressRow(
                          enrollment: enrollment,
                          onTap: () => _open(LearningCourseDetailScreen(slug: enrollment.course.slug, service: _service)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Finish every lesson and quiz in a course to get its certificate.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InProgressRow extends StatelessWidget {
  const _InProgressRow({required this.enrollment, required this.onTap});

  final LearningEnrollment enrollment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = enrollment.summary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const EmIconTile(Icons.menu_book_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enrollment.course.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    LearningProgressLine(done: summary.completedLessons, total: summary.totalLessons, short: true),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.quietIcon),
            ],
          ),
        ),
      ),
    );
  }
}
