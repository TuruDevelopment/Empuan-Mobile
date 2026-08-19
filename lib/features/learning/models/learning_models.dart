class LearningLifeStage {
  const LearningLifeStage({
    required this.code,
    required this.name,
    required this.minAge,
    this.maxAge,
  });

  final String code;
  final String name;
  final int minAge;
  final int? maxAge;

  factory LearningLifeStage.fromJson(Map<String, dynamic> json) {
    return LearningLifeStage(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      minAge: _asInt(json['min_age']),
      maxAge: json['max_age'] == null ? null : _asInt(json['max_age']),
    );
  }
}

class LearningCategory {
  const LearningCategory({
    required this.code,
    required this.name,
    this.description,
  });

  final String code;
  final String name;
  final String? description;

  factory LearningCategory.fromJson(Map<String, dynamic> json) {
    return LearningCategory(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class LearningProgress {
  const LearningProgress({
    required this.status,
    required this.positionSeconds,
    required this.progressPercent,
    this.completedAt,
  });

  final String status;
  final int positionSeconds;
  final double progressPercent;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed' || progressPercent >= 100;

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      status: json['status']?.toString() ?? 'not_started',
      positionSeconds: _asInt(json['position_seconds']),
      progressPercent: _asDouble(json['progress_percent']),
      completedAt: _asDateTime(json['completed_at']),
    );
  }
}

class LearningLessonSummary {
  const LearningLessonSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.type,
    required this.durationSeconds,
    required this.isPreview,
    required this.hasQuiz,
    this.summary,
    this.progress,
  });

  final int id;
  final String slug;
  final String title;
  final String? summary;
  final String type;
  final int durationSeconds;
  final bool isPreview;
  final bool hasQuiz;
  final LearningProgress? progress;

  factory LearningLessonSummary.fromJson(Map<String, dynamic> json) {
    return LearningLessonSummary(
      id: _asInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      type: json['type']?.toString() ?? 'article',
      durationSeconds: _asInt(json['duration_seconds']),
      isPreview: json['is_preview'] == true,
      hasQuiz: json['has_quiz'] == true,
      progress: json['progress'] is Map
          ? LearningProgress.fromJson(_asMap(json['progress']))
          : null,
    );
  }
}

class LearningQuizOption {
  const LearningQuizOption({required this.key, required this.text});

  final String key;
  final String text;

  factory LearningQuizOption.fromJson(Map<String, dynamic> json) {
    return LearningQuizOption(
      key: json['key']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

class LearningQuizQuestion {
  const LearningQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.points,
  });

  final int id;
  final String prompt;
  final List<LearningQuizOption> options;
  final int points;

  factory LearningQuizQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuizQuestion(
      id: _asInt(json['id']),
      prompt: json['prompt']?.toString() ?? '',
      options: _asList(json['options'])
          .map((item) => LearningQuizOption.fromJson(_asMap(item)))
          .toList(),
      points: _asInt(json['points'], fallback: 1),
    );
  }
}

class LearningQuiz {
  const LearningQuiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.passingScore,
    required this.attemptsUsed,
    required this.questions,
    this.instructions,
    this.maxAttempts,
  });

  final int id;
  final int lessonId;
  final String title;
  final String? instructions;
  final int passingScore;
  final int? maxAttempts;
  final int attemptsUsed;
  final List<LearningQuizQuestion> questions;

  bool get canAttempt =>
      maxAttempts == null || attemptsUsed < (maxAttempts ?? 0);

  factory LearningQuiz.fromJson(Map<String, dynamic> json) {
    return LearningQuiz(
      id: _asInt(json['id']),
      lessonId: _asInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      instructions: json['instructions']?.toString(),
      passingScore: _asInt(json['passing_score'], fallback: 70),
      maxAttempts:
          json['max_attempts'] == null ? null : _asInt(json['max_attempts']),
      attemptsUsed: _asInt(json['attempts_used']),
      questions: _asList(json['questions'])
          .map((item) => LearningQuizQuestion.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class LearningQuizResult {
  const LearningQuizResult({
    required this.questionId,
    required this.selectedOptionKey,
    required this.correctOptionKey,
    required this.correct,
    this.explanation,
  });

  final int questionId;
  final String selectedOptionKey;
  final String correctOptionKey;
  final bool correct;
  final String? explanation;

  factory LearningQuizResult.fromJson(Map<String, dynamic> json) {
    return LearningQuizResult(
      questionId: _asInt(json['question_id']),
      selectedOptionKey: json['selected_option_key']?.toString() ?? '',
      correctOptionKey: json['correct_option_key']?.toString() ?? '',
      correct: json['correct'] == true,
      explanation: json['explanation']?.toString(),
    );
  }
}

class LearningQuizAttempt {
  const LearningQuizAttempt({
    required this.id,
    required this.score,
    required this.passingScore,
    required this.passed,
    required this.earnedPoints,
    required this.totalPoints,
    required this.result,
    this.submittedAt,
  });

  final int id;
  final double score;
  final int passingScore;
  final bool passed;
  final int earnedPoints;
  final int totalPoints;
  final List<LearningQuizResult> result;
  final DateTime? submittedAt;

  factory LearningQuizAttempt.fromJson(Map<String, dynamic> json) {
    return LearningQuizAttempt(
      id: _asInt(json['id']),
      score: _asDouble(json['score']),
      passingScore: _asInt(json['passing_score']),
      passed: json['passed'] == true,
      earnedPoints: _asInt(json['earned_points']),
      totalPoints: _asInt(json['total_points']),
      result: _asList(json['result'])
          .map((item) => LearningQuizResult.fromJson(_asMap(item)))
          .toList(),
      submittedAt: _asDateTime(json['submitted_at']),
    );
  }
}

class LearningCertificate {
  const LearningCertificate({
    required this.publicId,
    required this.certificateNumber,
    required this.label,
    required this.recipientName,
    required this.courseTitle,
    required this.courseVersion,
    this.issuedAt,
  });

  final String publicId;
  final String certificateNumber;
  final String label;
  final String recipientName;
  final String courseTitle;
  final int courseVersion;
  final DateTime? issuedAt;

  factory LearningCertificate.fromJson(Map<String, dynamic> json) {
    return LearningCertificate(
      publicId: json['public_id']?.toString() ?? '',
      certificateNumber: json['certificate_number']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Certificate of Completion',
      recipientName: json['recipient_name']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      courseVersion: _asInt(json['course_version']),
      issuedAt: _asDateTime(json['issued_at']),
    );
  }
}

class LearningSection {
  const LearningSection({
    required this.id,
    required this.title,
    required this.lessons,
    this.description,
  });

  final int id;
  final String title;
  final String? description;
  final List<LearningLessonSummary> lessons;

  factory LearningSection.fromJson(Map<String, dynamic> json) {
    return LearningSection(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      lessons: _asList(json['lessons'])
          .map((item) => LearningLessonSummary.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class LearningSource {
  const LearningSource({
    required this.title,
    required this.url,
    this.publisher,
    this.publishedAt,
  });

  final String title;
  final String url;
  final String? publisher;
  final DateTime? publishedAt;

  factory LearningSource.fromJson(Map<String, dynamic> json) {
    return LearningSource(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publisher: json['publisher']?.toString(),
      publishedAt: _asDateTime(json['source_published_at']),
    );
  }
}

class LearningProgressSummary {
  const LearningProgressSummary({
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercent,
  });

  final int completedLessons;
  final int totalLessons;
  final double progressPercent;

  factory LearningProgressSummary.fromJson(Map<String, dynamic> json) {
    return LearningProgressSummary(
      completedLessons: _asInt(json['completed_lessons']),
      totalLessons: _asInt(json['total_lessons']),
      progressPercent: _asDouble(json['progress_percent']),
    );
  }
}

class LearningEnrollment {
  const LearningEnrollment({
    required this.status,
    required this.course,
    required this.summary,
    this.enrolledAt,
    this.completedAt,
    this.lastAccessedAt,
  });

  final String status;
  final LearningCourse course;
  final LearningProgressSummary summary;
  final DateTime? enrolledAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  factory LearningEnrollment.fromJson(Map<String, dynamic> json) {
    return LearningEnrollment(
      status: json['status']?.toString() ?? 'active',
      course: LearningCourse.fromJson(_asMap(json['course'])),
      summary: LearningProgressSummary.fromJson(_asMap(json['summary'])),
      enrolledAt: _asDateTime(json['enrolled_at']),
      completedAt: _asDateTime(json['completed_at']),
      lastAccessedAt: _asDateTime(json['last_accessed_at']),
    );
  }
}

class LearningCourse {
  const LearningCourse({
    required this.slug,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.minimumAge,
    required this.certificateEnabled,
    required this.isEnrolled,
    required this.lifeStages,
    required this.learningOutcomes,
    required this.sections,
    required this.sources,
    this.thumbnailUrl,
    this.category,
    this.description,
    this.certificateLabel,
    this.enrollment,
  });

  final String slug;
  final String title;
  final String summary;
  final String? thumbnailUrl;
  final int estimatedMinutes;
  final String difficulty;
  final int minimumAge;
  final bool certificateEnabled;
  final bool isEnrolled;
  final LearningCategory? category;
  final List<LearningLifeStage> lifeStages;
  final String? description;
  final List<String> learningOutcomes;
  final String? certificateLabel;
  final List<LearningSection> sections;
  final List<LearningSource> sources;
  final LearningProgressSummary? enrollment;

  Iterable<LearningLessonSummary> get lessons =>
      sections.expand((section) => section.lessons);

  factory LearningCourse.fromJson(Map<String, dynamic> json) {
    final enrollmentJson =
        json['enrollment'] is Map ? _asMap(json['enrollment']) : null;

    return LearningCourse(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      estimatedMinutes: _asInt(json['estimated_minutes']),
      difficulty: json['difficulty']?.toString() ?? 'beginner',
      minimumAge: _asInt(json['minimum_age'], fallback: 18),
      certificateEnabled: json['certificate_enabled'] == true,
      isEnrolled: json['is_enrolled'] == true || enrollmentJson != null,
      category: json['category'] is Map
          ? LearningCategory.fromJson(_asMap(json['category']))
          : null,
      lifeStages: _asList(json['life_stages'])
          .map((item) => LearningLifeStage.fromJson(_asMap(item)))
          .toList(),
      description: json['description']?.toString(),
      learningOutcomes: _asList(json['learning_outcomes'])
          .map((item) => item.toString())
          .toList(),
      certificateLabel: json['certificate_label']?.toString(),
      sections: _asList(json['sections'])
          .map((item) => LearningSection.fromJson(_asMap(item)))
          .toList(),
      sources: _asList(json['sources'])
          .map((item) => LearningSource.fromJson(_asMap(item)))
          .toList(),
      enrollment: enrollmentJson?['summary'] is Map
          ? LearningProgressSummary.fromJson(
              _asMap(enrollmentJson?['summary']),
            )
          : null,
    );
  }
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.slug,
    required this.title,
    required this.type,
    required this.durationSeconds,
    required this.isPreview,
    required this.hasQuiz,
    required this.courseSlug,
    required this.courseTitle,
    required this.sectionTitle,
    required this.sources,
    this.summary,
    this.body,
    this.content,
    this.mediaUrl,
    this.progress,
  });

  final int id;
  final String slug;
  final String title;
  final String? summary;
  final String type;
  final String? body;
  final Map<String, dynamic>? content;
  final String? mediaUrl;
  final int durationSeconds;
  final bool isPreview;
  final bool hasQuiz;
  final String courseSlug;
  final String courseTitle;
  final String sectionTitle;
  final List<LearningSource> sources;
  final LearningProgress? progress;

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    final course = _asMap(json['course']);
    final section = _asMap(json['section']);

    return LearningLesson(
      id: _asInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      type: json['type']?.toString() ?? 'article',
      body: json['body']?.toString(),
      content: json['content'] is Map ? _asMap(json['content']) : null,
      mediaUrl: json['media_url']?.toString(),
      durationSeconds: _asInt(json['duration_seconds']),
      isPreview: json['is_preview'] == true,
      hasQuiz: json['has_quiz'] == true,
      courseSlug: course['slug']?.toString() ?? '',
      courseTitle: course['title']?.toString() ?? '',
      sectionTitle: section['title']?.toString() ?? '',
      sources: _asList(json['sources'])
          .map((item) => LearningSource.fromJson(_asMap(item)))
          .toList(),
      progress: json['progress'] is Map
          ? LearningProgress.fromJson(_asMap(json['progress']))
          : null,
    );
  }
}

class LearningHomeData {
  const LearningHomeData({
    required this.categories,
    required this.recommendedCourses,
    required this.continueLearning,
    this.lifeStage,
  });

  final LearningLifeStage? lifeStage;
  final List<LearningCategory> categories;
  final List<LearningCourse> recommendedCourses;
  final List<LearningEnrollment> continueLearning;

  factory LearningHomeData.fromJson(Map<String, dynamic> json) {
    return LearningHomeData(
      lifeStage: json['life_stage'] is Map
          ? LearningLifeStage.fromJson(_asMap(json['life_stage']))
          : null,
      categories: _asList(json['categories'])
          .map((item) => LearningCategory.fromJson(_asMap(item)))
          .toList(),
      recommendedCourses: _asList(json['recommended_courses'])
          .map((item) => LearningCourse.fromJson(_asMap(item)))
          .toList(),
      continueLearning: _asList(json['continue_learning'])
          .map((item) => LearningEnrollment.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class LearningCoursePage {
  const LearningCoursePage({
    required this.courses,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<LearningCourse> courses;
  final int currentPage;
  final int lastPage;
  final int total;

  factory LearningCoursePage.fromEnvelope(Map<String, dynamic> json) {
    final meta = _asMap(json['meta']);

    return LearningCoursePage(
      courses: _asList(json['data'])
          .map((item) => LearningCourse.fromJson(_asMap(item)))
          .toList(),
      currentPage: _asInt(meta['current_page'], fallback: 1),
      lastPage: _asInt(meta['last_page'], fallback: 1),
      total: _asInt(meta['total']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  return value == null ? null : DateTime.tryParse(value.toString());
}
