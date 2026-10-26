import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/content_repository.dart';
import '../../data/offline.dart';
import '../../services/auth_service.dart';
import '../learning/services/learning_progress_sync_service.dart';
import '../learning/services/learning_service.dart';

/// Saves the courses someone is taking, and recent Her Voice pictures, while
/// the phone is online, so they can be read later without a connection.
///
/// Runs a little after the app opens and again when the connection comes
/// back, at most every half hour, and follows the "Saved for offline"
/// switches. Videos are left out: they're too big and stream instead.
class OfflineSync {
  OfflineSync._();

  static final instance = OfflineSync._();

  static const _gap = Duration(minutes: 30);
  static const _maxCourses = 5;
  static const _maxLessons = 40;
  static const _maxArticleImages = 12;

  bool _started = false;
  bool _running = false;
  DateTime? _lastRun;

  /// Called each time the signed-in app opens.
  void start() {
    if (!_started) {
      _started = true;
      OfflineStatus.instance.reconnects.addListener(_kick);
    }
    // Leave the first seconds to the screen the person is looking at.
    if (_signedIn) Timer(const Duration(seconds: 8), _kick);
  }

  bool get _signedIn => AuthService.token?.isNotEmpty ?? false;

  void _kick() {
    unawaited(_sendProgress());
    unawaited(run());
  }

  /// Lessons finished offline wait in a queue; send them now.
  Future<void> _sendProgress() async {
    if (!_signedIn || OfflineStatus.instance.offline) return;
    try {
      await LearningProgressSyncService(LearningService()).syncPending();
    } catch (_) {}
  }

  /// [force] ignores the half-hour gap, e.g. right after turning saving on.
  Future<void> run({bool force = false, LearningService? learning, ArticlesRepository? articles}) async {
    if (_running || !_signedIn) return;
    final last = _lastRun;
    if (!force && last != null && DateTime.now().difference(last) < _gap) return;
    if (!await OfflinePrefs.autoSaveCourses()) return;
    if (await OfflinePrefs.wifiOnly() && !await OfflineStatus.instance.onWifi()) return;
    if (OfflineStatus.instance.offline) return;

    _running = true;
    try {
      await _saveCourses(learning ?? LearningService());
      await _saveArticleImages(articles ?? ArticlesRepository());
      _lastRun = DateTime.now();
    } catch (e) {
      debugPrint('[OFFLINE_SYNC] Stopped: ${e.runtimeType}');
    } finally {
      _running = false;
    }
  }

  Future<void> _saveCourses(LearningService learning) async {
    final home = await learning.getHome();
    var lessons = 0;
    for (final enrollment in home.continueLearning.take(_maxCourses)) {
      final course = await learning.getCourse(enrollment.course.slug);
      await OfflineImages.prefetch(course.thumbnailUrl);
      for (final summary in course.lessons) {
        if (lessons++ >= _maxLessons || OfflineStatus.instance.offline) return;
        final lesson = await learning.getLesson(summary.id);
        if (lesson.type == 'infographic') await OfflineImages.prefetch(lesson.mediaUrl);
      }
    }
  }

  Future<void> _saveArticleImages(ArticlesRepository articles) async {
    // Fetching the list also saves it, text included.
    final list = await articles.articles();
    for (final article in list.take(_maxArticleImages)) {
      if (OfflineStatus.instance.offline) return;
      await OfflineImages.prefetch(article.imageUrl);
    }
  }

  @visibleForTesting
  void reset() {
    _running = false;
    _lastRun = null;
  }
}
