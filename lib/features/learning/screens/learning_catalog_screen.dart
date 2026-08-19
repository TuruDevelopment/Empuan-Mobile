import 'dart:async';

import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_course_detail_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';

class LearningCatalogScreen extends StatefulWidget {
  const LearningCatalogScreen({
    super.key,
    required this.service,
    this.initialCategory,
  });

  final LearningService service;
  final String? initialCategory;

  @override
  State<LearningCatalogScreen> createState() => _LearningCatalogScreenState();
}

class _LearningCatalogScreenState extends State<LearningCatalogScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _category;
  late Future<LearningCoursePage> _coursesFuture;
  late Future<LearningHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _homeFuture = widget.service.getHome();
    _coursesFuture = _loadCourses();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<LearningCoursePage> _loadCourses() {
    return widget.service.getCourses(
      category: _category,
      search: _searchController.text,
      perPage: 50,
    );
  }

  Future<void> _reload() async {
    final coursesFuture = _loadCourses();
    setState(() {
      _coursesFuture = coursesFuture;
    });
    await coursesFuture;
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  void _setCategory(String? category) {
    setState(() {
      _category = category;
      _coursesFuture = _loadCourses();
    });
  }

  void _openCourse(LearningCourse course) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LearningCourseDetailScreen(
              slug: course.slug,
              service: widget.service,
            ),
          ),
        )
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Learning Catalog')),
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Search courses',
                      hintText: 'Example: career or finance',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                _reload();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<LearningHomeData>(
                    future: _homeFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All'),
                                selected: _category == null,
                                onSelected: (_) => _setCategory(null),
                              ),
                            ),
                            ...snapshot.data!.categories.map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category.name),
                                  selected: _category == category.code,
                                  onSelected: (_) =>
                                      _setCategory(category.code),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<LearningCoursePage>(
              future: _coursesFuture,
              builder: (context, snapshot) {
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

                final courses = snapshot.requireData.courses;

                if (courses.isEmpty) {
                  return const LearningEmptyState(
                    title: 'No courses found',
                    message: 'Try a different search term or category.',
                    icon: Icons.search_off_rounded,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return LearningCourseCard(
                        course: course,
                        onTap: () => _openCourse(course),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
