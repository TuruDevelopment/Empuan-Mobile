import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_progress_sync_service.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Learning models', () {
    test('recognizes a missing date of birth access error', () {
      const missingDob = LearningApiException(
        'Add your date of birth to your profile to access Learning.',
        statusCode: 403,
      );
      const underage = LearningApiException(
        'Learning is only available to users aged 18 and above.',
        statusCode: 403,
      );

      expect(missingDob.requiresDateOfBirth, isTrue);
      expect(underage.requiresDateOfBirth, isFalse);
    });

    test('parses a course card without hardcoded content assumptions', () {
      final course = LearningCourse.fromJson({
        'slug': 'personal-branding',
        'title': 'Personal Branding',
        'summary': 'Summary',
        'estimated_minutes': 25,
        'difficulty': 'beginner',
        'minimum_age': 18,
        'certificate_enabled': true,
        'is_enrolled': false,
        'category': {'code': 'career', 'name': 'Career'},
        'life_stages': [
          {
            'code': 'age_18_24',
            'name': 'Ages 18-24',
            'min_age': 18,
            'max_age': 24,
          },
        ],
      });

      expect(course.slug, 'personal-branding');
      expect(course.category?.name, 'Career');
      expect(course.lifeStages.single.minAge, 18);
      expect(course.sections, isEmpty);
    });

    test('parses quiz options and attempt result', () {
      final quiz = LearningQuiz.fromJson({
        'id': 3,
        'lesson_id': 7,
        'title': 'Knowledge Check',
        'passing_score': 70,
        'attempts_used': 0,
        'questions': [
          {
            'id': 9,
            'prompt': 'Choose an answer',
            'points': 1,
            'options': [
              {'key': 'A', 'text': 'Option A'},
              {'key': 'B', 'text': 'Option B'},
            ],
          },
        ],
      });

      expect(quiz.questions.single.options.length, 2);
      expect(quiz.questions.single.options.last.key, 'B');
      expect(quiz.canAttempt, isTrue);
    });

    test('uses the listed lesson count when sections are left out', () {
      final course = LearningCourse.fromJson({
        'slug': 'salary',
        'title': 'Negotiating your salary',
        'lessons_count': 4,
        'estimated_minutes': 30,
        'certificate_enabled': true,
      });

      expect(course.lessonCount, 4);
      expect(courseMeta(course), '4 lessons · 30 min · Certificate');
    });
  });

  group('Learning text helpers', () {
    test('turns HTML into paragraphs and keeps plain text paragraphs', () {
      expect(
        htmlToParagraphs('<p>First &amp; best.</p><p>Second<br>line</p><ul><li>One</li></ul>'),
        ['First & best.', 'Second', 'line', '• One'],
      );
      expect(htmlToParagraphs('One.\n\nTwo.'), ['One.', 'Two.']);
      expect(htmlToParagraphs(null), isEmpty);
    });

    test('reads life stage names inside a sentence', () {
      expect(inSentence('Ages 25–34'), 'ages 25–34');
      expect(inSentence('UK students'), 'UK students');
    });
  });

  group('Learning progress sync', () {
    test('keeps offline completion and synchronizes it later', () async {
      SharedPreferences.setMockInitialValues({});
      final service = _FakeLearningService()..offline = true;
      final sync = LearningProgressSyncService(service);

      final queued = await sync.completeLesson(42);
      expect(queued.synced, isFalse);

      service.offline = false;
      final synced = await sync.syncPending();

      expect(synced, 1);
      expect(service.lessonIds, [42, 42]);
    });
  });
}

class _FakeLearningService extends LearningService {
  bool offline = false;
  final List<int> lessonIds = [];

  @override
  Future<LearningProgress> updateProgress(
    int lessonId, {
    int? positionSeconds,
    double? progressPercent,
    bool? completed,
  }) async {
    lessonIds.add(lessonId);

    if (offline) {
      throw const LearningApiException('Offline');
    }

    return const LearningProgress(
      status: 'completed',
      positionSeconds: 0,
      progressPercent: 100,
    );
  }
}
