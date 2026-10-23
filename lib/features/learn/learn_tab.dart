import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
import '../learning/screens/learning_certificates_screen.dart';
import '../learning/services/learning_service.dart';
import 'learn_articles_view.dart';
import 'learn_courses_view.dart';
import 'learn_segmented_control.dart';

/// Learn tab root: courses and Her Voice articles.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key, this.learningService, this.articlesRepository});

  final LearningService? learningService;
  final ArticlesRepository? articlesRepository;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  late final LearningService _learning = widget.learningService ?? LearningService();
  late final ArticlesRepository _articles = widget.articlesRepository ?? ArticlesRepository();
  int _segment = 0;

  // Articles load only once the segment is first opened.
  final Set<int> _built = {0};

  void _select(int index) {
    setState(() {
      _segment = index;
      _built.add(index);
    });
  }

  Widget _segmentView(int index) => switch (index) {
        0 => LearnCoursesView(service: _learning),
        _ => LearnArticlesView(repository: _articles),
      };

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Semantics(header: true, child: Text('Learn', style: Theme.of(context).textTheme.headlineLarge)),
                  ),
                  EmIconButton(
                    icon: Icons.workspace_premium_outlined,
                    label: 'My certificates',
                    style: EmIconButtonStyle.soft,
                    onPressed: () => pushScreen<void>(context, LearningCertificatesScreen(service: _learning)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child:
                  LearnSegmentedControl(labels: const ['Courses', 'Articles'], selected: _segment, onChanged: _select),
            ),
            const SizedBox(height: 16),
            Expanded(
              // Both segments stay mounted so switching keeps scroll and data;
              // the inactive one fades out and stops taking input.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final index in _built)
                    KeyedSubtree(
                      key: ValueKey(index),
                      child: IgnorePointer(
                        ignoring: index != _segment,
                        child: ExcludeSemantics(
                          excluding: index != _segment,
                          child: AnimatedOpacity(
                            opacity: index == _segment ? 1 : 0,
                            duration: duration,
                            curve: EmMotion.enter,
                            child: TickerMode(enabled: index == _segment, child: _segmentView(index)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
