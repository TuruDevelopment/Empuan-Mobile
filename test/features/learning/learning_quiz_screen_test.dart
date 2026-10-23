import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_course_detail_screen.dart';
import 'package:Empuan/features/learning/screens/learning_quiz_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quiz goes one question at a time and explains wrong answers', (tester) async {
    final service = _FakeLearningService();
    await tester.pumpWidget(MaterialApp(home: LearningQuizScreen(lessonId: 7, service: service)));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('Pass with 70%'), findsOneWidget);
    expect(find.text('Attempt 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Planning where your money goes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 2'), findsOneWidget);
    await tester.tap(find.text('Rent and monthly bills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(service.submitted, {1: 'A', 2: 'C'});
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Almost there'), findsOneWidget);
    expect(find.text('1 of 2 correct. You need 70% to pass. 2 attempts left.'), findsOneWidget);
    expect(find.text('Question 2 · Not quite'), findsOneWidget);
    expect(find.textContaining('Savings and paying off debt'), findsOneWidget);
    expect(find.text('Rent and bills are needs.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('course detail offers to continue with the next lesson', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: LearningCourseDetailScreen(slug: 'budgeting', service: _FakeLearningService())));
    await tester.pumpAndSettle();

    expect(find.text('Budgeting basics'), findsWidgets);
    expect(find.text('1 of 2 lessons'), findsOneWidget);
    expect(find.text('Continue: The 50/30/20 split'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Article · 5 min · Done'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Article · 5 min · Done'), findsOneWidget);
    expect(find.text('Video · 7 min · Quiz'), findsOneWidget);
  });
}

class _FakeLearningService extends LearningService {
  Map<int, String>? submitted;

  @override
  Future<LearningQuiz> getQuiz(int lessonId) async => LearningQuiz.fromJson({
        'id': 3,
        'lesson_id': lessonId,
        'title': 'Check',
        'passing_score': 70,
        'max_attempts': 3,
        'attempts_used': 0,
        'questions': [
          {
            'id': 1,
            'prompt': 'What is a budget mainly for?',
            'options': [
              {'key': 'A', 'text': 'Planning where your money goes'},
              {'key': 'B', 'text': 'Tracking only big purchases'},
            ],
          },
          {
            'id': 2,
            'prompt': 'In the 50/30/20 rule, what is the 20% for?',
            'options': [
              {'key': 'A', 'text': 'Things you want'},
              {'key': 'B', 'text': 'Savings and paying off debt'},
              {'key': 'C', 'text': 'Rent and monthly bills'},
            ],
          },
        ],
      });

  @override
  Future<LearningQuizAttempt> submitQuiz(int quizId, Map<int, String> answers) async {
    submitted = answers;
    return LearningQuizAttempt.fromJson({
      'id': 9,
      'score': 50,
      'passing_score': 70,
      'passed': false,
      'result': [
        {'question_id': 1, 'selected_option_key': 'A', 'correct_option_key': 'A', 'correct': true},
        {
          'question_id': 2,
          'selected_option_key': 'C',
          'correct_option_key': 'B',
          'correct': false,
          'explanation': 'Rent and bills are needs.',
        },
      ],
    });
  }

  @override
  Future<LearningCourse> getCourse(String slug) async => LearningCourse.fromJson({
        'slug': slug,
        'title': 'Budgeting basics',
        'summary': '<p>Build a monthly budget.</p>',
        'estimated_minutes': 25,
        'certificate_enabled': true,
        'is_enrolled': true,
        'learning_outcomes': ['Split your income'],
        'sections': [
          {
            'id': 1,
            'title': 'Getting started',
            'lessons': [
              {
                'id': 1,
                'title': 'What a budget is for',
                'type': 'article',
                'duration_seconds': 300,
                'progress': {'status': 'completed', 'progress_percent': 100},
              },
              {'id': 2, 'title': 'The 50/30/20 split', 'type': 'video', 'duration_seconds': 420, 'has_quiz': true},
            ],
          },
        ],
      });
}
