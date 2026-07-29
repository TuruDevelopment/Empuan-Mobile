import 'dart:async';

import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_catalog_screen.dart';
import 'package:Empuan/features/learning/screens/learning_course_detail_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/services/learning_progress_sync_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key, this.service});

  final LearningService? service;

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  late final LearningService _service;
  late Future<LearningHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LearningService();
    _homeFuture = _initialize();
  }

  Future<LearningHomeData> _initialize() async {
    unawaited(LearningProgressSyncService(_service).syncPending());
    return _service.getHome();
  }

  Future<void> _reload() async {
    final homeFuture = _service.getHome();
    setState(() {
      _homeFuture = homeFuture;
    });
    await homeFuture;
  }

  void _openCatalog({String? category}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LearningCatalogScreen(
              service: _service,
              initialCategory: category,
            ),
          ),
        )
        .then((_) => _reload());
  }

  void _openCourse(LearningCourse course) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LearningCourseDetailScreen(
              slug: course.slug,
              service: _service,
            ),
          ),
        )
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Empuan Learning'),
      ),
      body: FutureBuilder<LearningHomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return LearningErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          return _LearningHomeContent(
            data: snapshot.requireData,
            onRefresh: _reload,
            onOpenCatalog: _openCatalog,
            onOpenCourse: _openCourse,
          );
        },
      ),
    );
  }
}

class _LearningHomeContent extends StatelessWidget {
  const _LearningHomeContent({
    required this.data,
    required this.onRefresh,
    required this.onOpenCatalog,
    required this.onOpenCourse,
  });

  final LearningHomeData data;
  final Future<void> Function() onRefresh;
  final void Function({String? category}) onOpenCatalog;
  final ValueChanged<LearningCourse> onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        MediaQuery.sizeOf(context).width >= 700 ? 40.0 : 20.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          20,
          horizontalPadding,
          40,
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LearningHero(lifeStage: data.lifeStage),
                const SizedBox(height: 24),
                if (data.continueLearning.isNotEmpty) ...[
                  const LearningSectionTitle(
                    title: 'Lanjutkan belajar',
                    subtitle: 'Teruskan dari materi terakhirmu',
                  ),
                  const SizedBox(height: 14),
                  ...data.continueLearning.map(
                    (enrollment) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LearningCourseCard(
                        course: enrollment.course,
                        progress: enrollment.summary,
                        onTap: () => onOpenCourse(enrollment.course),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                LearningSectionTitle(
                  title: 'Pilih topik',
                  subtitle: 'Materi dikelola dan diterbitkan oleh admin',
                  action: TextButton(
                    onPressed: () => onOpenCatalog(),
                    child: const Text('Lihat semua'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: data.categories
                      .map(
                        (category) => ActionChip(
                          avatar: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(category.name),
                          onPressed: () =>
                              onOpenCatalog(category: category.code),
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.8),
                          ),
                          backgroundColor: AppColors.surface,
                          labelStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 28),
                LearningSectionTitle(
                  title: 'Rekomendasi untukmu',
                  subtitle: data.lifeStage == null
                      ? 'Course terbaru yang dapat kamu pelajari'
                      : 'Disesuaikan untuk ${data.lifeStage!.name}',
                ),
                const SizedBox(height: 14),
                if (data.recommendedCourses.isEmpty)
                  const LearningEmptyState(
                    title: 'Materi segera hadir',
                    message:
                        'Admin belum menerbitkan materi untuk tahap kehidupanmu.',
                  )
                else
                  ...data.recommendedCourses.map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LearningCourseCard(
                        course: course,
                        onTap: () => onOpenCourse(course),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const _EducationNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero({this.lifeStage});

  final LearningLifeStage? lifeStage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belajar sesuai tahap kehidupanmu',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 23,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lifeStage == null
                ? 'Materi praktis untuk perempuan usia 18 tahun ke atas.'
                : 'Pilihan materi untuk tahap ${lifeStage!.name}.',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationNotice extends StatelessWidget {
  const _EducationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Materi bersifat edukasi umum dan tidak menggantikan nasihat '
              'profesional medis, hukum, atau keuangan.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
