import 'dart:async';
import 'dart:convert';

import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:http/http.dart' as http;

class LearningApiException implements Exception {
  const LearningApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class LearningService {
  LearningService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  Future<LearningHomeData> getHome() async {
    final envelope = await _request('GET', ApiConfig.learningHome);
    return LearningHomeData.fromJson(_map(envelope['data']));
  }

  Future<LearningCoursePage> getCourses({
    String? category,
    String? lifeStage,
    String? search,
    bool recommended = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final envelope = await _request(
      'GET',
      ApiConfig.learningCourses,
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (lifeStage != null && lifeStage.isNotEmpty) 'life_stage': lifeStage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (recommended) 'recommended': '1',
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    return LearningCoursePage.fromEnvelope(envelope);
  }

  Future<LearningCourse> getCourse(String slug) async {
    final envelope = await _request('GET', ApiConfig.learningCourse(slug));
    return LearningCourse.fromJson(_map(envelope['data']));
  }

  Future<LearningEnrollment> enroll(String slug) async {
    final envelope = await _request('POST', ApiConfig.learningEnroll(slug));
    return LearningEnrollment.fromJson(_map(envelope['data']));
  }

  Future<LearningLesson> getLesson(int id) async {
    final envelope = await _request('GET', ApiConfig.learningLesson(id));
    return LearningLesson.fromJson(_map(envelope['data']));
  }

  Future<LearningProgress> updateProgress(
    int lessonId, {
    int? positionSeconds,
    double? progressPercent,
    bool? completed,
  }) async {
    final envelope = await _request(
      'PUT',
      ApiConfig.learningLessonProgress(lessonId),
      body: {
        if (positionSeconds != null) 'position_seconds': positionSeconds,
        if (progressPercent != null) 'progress_percent': progressPercent,
        if (completed != null) 'completed': completed,
      },
    );
    return LearningProgress.fromJson(_map(envelope['data']));
  }

  Future<LearningQuiz> getQuiz(int lessonId) async {
    final envelope =
        await _request('GET', ApiConfig.learningLessonQuiz(lessonId));
    return LearningQuiz.fromJson(_map(envelope['data']));
  }

  Future<LearningQuizAttempt> submitQuiz(
    int quizId,
    Map<int, String> answers,
  ) async {
    final envelope = await _request(
      'POST',
      ApiConfig.learningQuizAttempts(quizId),
      body: {
        'answers': answers.map(
          (questionId, answer) => MapEntry('$questionId', answer),
        ),
      },
    );
    return LearningQuizAttempt.fromJson(_map(envelope['data']));
  }

  Future<LearningCertificate> getCertificate(String courseSlug) async {
    final envelope = await _request(
      'GET',
      ApiConfig.learningCertificate(courseSlug),
    );
    return LearningCertificate.fromJson(_map(envelope['data']));
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(ApiConfig.getUrl(path)).replace(
      queryParameters: query?.isEmpty == true ? null : query,
    );

    try {
      late http.Response response;
      final headers = AuthService.getAuthHeaders();

      switch (method) {
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
          break;
        default:
          response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : _map(jsonDecode(response.body));

      if (response.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const LearningApiException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw LearningApiException(
          decoded['message']?.toString() ??
              'Learning could not be loaded. Please try again.',
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on TimeoutException {
      throw const LearningApiException(
        'The connection timed out. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const LearningApiException(
        'The Learning response could not be read.',
      );
    } on LearningApiException {
      rethrow;
    } catch (_) {
      throw const LearningApiException(
        'Could not connect to Learning. Please try again.',
      );
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}
