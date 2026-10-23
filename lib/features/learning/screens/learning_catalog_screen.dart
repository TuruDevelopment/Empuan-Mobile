import 'dart:async';

import 'package:flutter/material.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';
import 'learning_course_detail_screen.dart';

class LearningCatalogScreen extends StatefulWidget {
  const LearningCatalogScreen({super.key, this.service, this.initialCategory, this.autofocus = false});

  final LearningService? service;
  final String? initialCategory;

  /// Opens the keyboard straight away when the user came here to search.
  final bool autofocus;

  @override
  State<LearningCatalogScreen> createState() => _LearningCatalogScreenState();
}

class _LearningCatalogScreenState extends State<LearningCatalogScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  final _search = TextEditingController();
  Timer? _debounce;
  late String? _category = widget.initialCategory;
  late Future<LearningCoursePage> _coursesFuture = _loadCourses();
  List<LearningCategory> _categories = const [];
  LearningEntrance _entrance = LearningEntrance();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final home = await _service.getHome();
      if (mounted) setState(() => _categories = home.categories);
    } catch (_) {
      // Without categories the search still works; the chip row stays hidden.
    }
  }

  Future<LearningCoursePage> _loadCourses() =>
      _service.getCourses(category: _category, search: _search.text, perPage: 50);

  Future<void> _reload({bool newResults = false}) async {
    final future = _loadCourses();
    setState(() {
      _coursesFuture = future;
      if (newResults) _entrance = LearningEntrance();
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  void _runSearch() => _reload(newResults: true);

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  void _clearSearch() {
    _search.clear();
    _debounce?.cancel();
    _runSearch();
  }

  void _setCategory(String? code) {
    setState(() {
      _category = code;
      _coursesFuture = _loadCourses();
      _entrance = LearningEntrance();
    });
  }

  Future<void> _openCourse(LearningCourse course) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LearningCourseDetailScreen(slug: course.slug, service: _service)),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _category == null ? 0 : _categories.indexWhere((c) => c.code == _category) + 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                children: [
                  EmIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      autofocus: widget.autofocus,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _runSearch(),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search courses',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                                onPressed: _clearSearch,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: EmChipBar(
                  labels: ['All', ..._categories.map((c) => c.name)],
                  selected: selectedIndex < 0 ? 0 : selectedIndex,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onSelected: (i) => _setCategory(i == 0 ? null : _categories[i - 1].code),
                ),
              ),
            Expanded(
              child: FutureBuilder<LearningCoursePage>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  final (key, child) = _state(snapshot);
                  return EmStateSwitcher(stateKey: key, child: child);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Widget) _state(AsyncSnapshot<LearningCoursePage> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return ('loading', const Padding(padding: EdgeInsets.only(top: 16), child: LearningCourseSkeleton()));
    }
    if (snapshot.hasError) {
      return (
        'error',
        LearningScrollableState(
          onRefresh: _reload,
          child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
        )
      );
    }
    final page = snapshot.requireData;
    final courses = page.courses;
    if (courses.isEmpty) {
      return (
        'empty',
        LearningScrollableState(
          onRefresh: _reload,
          child: EmStateView(
            icon: Icons.search_off_rounded,
            title: 'No courses found',
            message: _search.text.trim().isEmpty
                ? 'There are no courses in this topic yet.'
                : 'Nothing matches “${_search.text.trim()}”. Try another word or topic.',
          ),
        )
      );
    }
    final count = page.total > courses.length ? page.total : courses.length;
    return (
      'results',
      RefreshIndicator(
        onRefresh: _reload,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: courses.length + 1,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 10 : 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return EmAnimatedSwap(
                  valueKey: count,
                  child: Text(
                    '$count ${count == 1 ? 'course' : 'courses'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ));
            }
            final course = courses[i - 1];
            return _entrance.wrap(i, LearningCourseRow(course: course, onTap: () => _openCourse(course)));
          },
        ),
      )
    );
  }
}
