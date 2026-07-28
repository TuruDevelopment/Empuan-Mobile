import 'dart:convert';

import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningSyncResult {
  const LearningSyncResult({required this.synced, this.progress});

  final bool synced;
  final LearningProgress? progress;
}

class LearningProgressSyncService {
  LearningProgressSyncService(this._service);

  final LearningService _service;
  static const _pendingKey = 'learning_pending_progress_v1';

  Future<LearningSyncResult> completeLesson(int lessonId) async {
    final payload = <String, dynamic>{
      'lesson_id': lessonId,
      'completed': true,
      'progress_percent': 100,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _upsertPending(payload);

    try {
      final progress = await _service.updateProgress(
        lessonId,
        completed: true,
        progressPercent: 100,
      );
      await _removePending(lessonId);
      return LearningSyncResult(synced: true, progress: progress);
    } on LearningApiException catch (error) {
      if (error.statusCode != null) {
        await _removePending(lessonId);
        rethrow;
      }
      return const LearningSyncResult(synced: false);
    }
  }

  Future<int> syncPending() async {
    final items = await _readPending();
    var synced = 0;

    for (final item in List<Map<String, dynamic>>.from(items).take(10)) {
      final lessonId = item['lesson_id'] as int?;
      if (lessonId == null) continue;

      try {
        await _service.updateProgress(
          lessonId,
          completed: item['completed'] == true,
          progressPercent: (item['progress_percent'] as num?)?.toDouble(),
        );
        await _removePending(lessonId);
        synced++;
      } on LearningApiException catch (error) {
        if (error.statusCode != null) {
          await _removePending(lessonId);
        }
      }
    }

    return synced;
  }

  Future<void> _upsertPending(Map<String, dynamic> payload) async {
    final items = await _readPending();
    items.removeWhere(
      (item) => item['lesson_id'] == payload['lesson_id'],
    );
    items.add(payload);
    await _writePending(items);
  }

  Future<void> _removePending(int lessonId) async {
    final items = await _readPending();
    items.removeWhere((item) => item['lesson_id'] == lessonId);
    await _writePending(items);
  }

  Future<List<Map<String, dynamic>>> _readPending() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _writePending(List<Map<String, dynamic>> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingKey, jsonEncode(items));
  }
}
