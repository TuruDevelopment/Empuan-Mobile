import 'package:Empuan/features/learn/learn_courses_view.dart';
import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpView(WidgetTester tester, LearningService service) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LearnCoursesView(service: service))));
    await tester.pumpAndSettle();
  }

  testWidgets('asks for a date of birth, saves it and then shows courses', (tester) async {
    final service = _FakeLearningService(requireDob: true);
    await pumpView(tester, service);

    expect(find.text('Add your date of birth'), findsOneWidget);

    await tester.tap(find.text('Save and show courses'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your date of birth.'), findsOneWidget);
    expect(service.updatedDateOfBirth, isNull);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save and show courses'));
    await tester.pumpAndSettle();

    expect(service.updatedDateOfBirth, isNotNull);
    expect(find.text('Add your date of birth'), findsNothing);
    expect(find.text('Picked for ages 25–34'), findsOneWidget);
    expect(find.text('Negotiating your salary'), findsOneWidget);
    expect(find.text('4 lessons · 30 min · Certificate'), findsOneWidget);
  });

  testWidgets('shows continue, topics and the disclaimer', (tester) async {
    await pumpView(tester, _FakeLearningService());

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Budgeting basics'), findsOneWidget);
    expect(find.text('Next: The 50/30/20 split · 7 min'), findsOneWidget);
    expect(find.text('1 of 3 lessons'), findsOneWidget);
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Career'), findsWidgets);
    expect(find.textContaining('General education only.'), findsOneWidget);
  });

  testWidgets('shows an error with a working retry', (tester) async {
    final service = _FakeLearningService(failures: 1);
    await pumpView(tester, service);

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Negotiating your salary'), findsOneWidget);
  });
}

class _FakeLearningService extends LearningService {
  _FakeLearningService({this.requireDob = false, this.failures = 0});

  final bool requireDob;
  int failures;
  DateTime? updatedDateOfBirth;

  @override
  Future<LearningHomeData> getHome() async {
    if (requireDob && updatedDateOfBirth == null) {
      throw const LearningApiException('Add your date of birth to your profile to access Learning.', statusCode: 403);
    }
    if (failures > 0) {
      failures--;
      throw const LearningApiException('Could not connect to Learning. Please try again.');
    }
    return LearningHomeData.fromJson({
      'life_stage': {'code': 'age_25_34', 'name': 'Ages 25–34', 'min_age': 25, 'max_age': 34},
      'categories': [
        {'code': 'career', 'name': 'Career'},
      ],
      'recommended_courses': [
        {
          'slug': 'salary',
          'title': 'Negotiating your salary',
          'summary': '',
          'estimated_minutes': 30,
          'certificate_enabled': true,
          'lessons_count': 4,
          'category': {'code': 'career', 'name': 'Career'},
        },
      ],
      'continue_learning': [
        {
          'status': 'active',
          'course': {
            'slug': 'budgeting',
            'title': 'Budgeting basics',
            'summary': '',
            'is_enrolled': true,
            'sections': [
              {
                'id': 1,
                'title': 'Getting started',
                'lessons': [
                  {
                    'id': 1,
                    'title': 'What a budget is for',
                    'duration_seconds': 300,
                    'progress': {'status': 'completed', 'progress_percent': 100},
                  },
                  {'id': 2, 'title': 'The 50/30/20 split', 'duration_seconds': 420},
                  {'id': 3, 'title': 'Emergency savings', 'duration_seconds': 240},
                ],
              },
            ],
          },
          'summary': {'completed_lessons': 1, 'total_lessons': 3, 'progress_percent': 33},
        },
      ],
    });
  }

  @override
  Future<void> updateDateOfBirth(DateTime dateOfBirth) async {
    updatedDateOfBirth = dateOfBirth;
  }

  @override
  Future<LearningProgress> updateProgress(int lessonId,
      {int? positionSeconds, double? progressPercent, bool? completed}) async {
    return const LearningProgress(status: 'completed', positionSeconds: 0, progressPercent: 100);
  }
}
