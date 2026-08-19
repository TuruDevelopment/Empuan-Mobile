import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_progress_sync_service.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Learning models', () {
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
