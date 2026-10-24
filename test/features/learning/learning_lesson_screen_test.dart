import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_lesson_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final course = LearningCourse.fromJson({
    'slug': 'budgeting',
    'title': 'Budgeting basics',
    'is_enrolled': true,
    'sections': [
      {
        'id': 1,
        'title': 'Getting started',
        'lessons': [
          {'id': 1, 'title': 'What a budget is for'},
          {'id': 2, 'title': 'The 50/30/20 split'},
        ],
      },
    ],
  });

  testWidgets('marks a lesson done and opens the next one', (tester) async {
    final service = _FakeLearningService();
    await tester.pumpWidget(
      MaterialApp(home: LearningLessonScreen(lessonId: 1, service: service, canTrackProgress: true, course: course)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesson 1 of 2'), findsOneWidget);
    expect(find.text('Getting started first paragraph.'), findsOneWidget);
    expect(find.text('Second paragraph.'), findsOneWidget);

    await tester.tap(find.text('Mark done and continue'));
    await tester.pumpAndSettle();

    expect(service.completed, [1]);
    expect(find.text('Lesson 2 of 2'), findsOneWidget);
    expect(find.text('The 50/30/20 split'), findsOneWidget);
  });

  testWidgets('preview readers are asked to enroll instead', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home:
            LearningLessonScreen(lessonId: 1, service: _FakeLearningService(), canTrackProgress: false, course: course),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enroll to continue'), findsOneWidget);
    expect(find.text('Mark done and continue'), findsNothing);
  });
}

class _FakeLearningService extends LearningService {
  final List<int> completed = [];

  @override
  Future<LearningLesson> getLesson(int id) async => LearningLesson.fromJson({
        'id': id,
        'title': id == 1 ? 'What a budget is for' : 'The 50/30/20 split',
        'type': 'article',
        'body': '<p>Getting started first paragraph.</p><p>Second paragraph.</p>',
        'course': {'slug': 'budgeting', 'title': 'Budgeting basics'},
        'section': {'title': 'Getting started'},
      });

  @override
  Future<LearningProgress> updateProgress(int lessonId,
      {int? positionSeconds, double? progressPercent, bool? completed}) async {
    this.completed.add(lessonId);
    return const LearningProgress(status: 'completed', positionSeconds: 0, progressPercent: 100);
  }
}
