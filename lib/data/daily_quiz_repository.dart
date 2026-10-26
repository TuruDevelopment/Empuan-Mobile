import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../ui/em_ui.dart' show apiDate;
import 'api.dart';

class DailyQuestion {
  const DailyQuestion({required this.id, required this.prompt, required this.correctAnswer, this.options = const []});

  final int id;
  final String prompt;
  final String correctAnswer;
  final List<String> options;

  bool isCorrect(String option) => option.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

  DailyQuestion withOptions(List<String> options) =>
      DailyQuestion(id: id, prompt: prompt, correctAnswer: correctAnswer, options: options);
}

/// Today's questions come from the shared `/questions` bank: the same two for
/// everyone on a given day. Which days were answered is kept on the device.
class DailyQuizRepository {
  DailyQuizRepository({Api? api}) : _api = api ?? Api();

  final Api _api;
  static const perDay = 2;
  static const _answeredKey = 'daily_quiz_answered_days';

  Future<List<DailyQuestion>> today([DateTime? now]) async {
    final all = asMapList(await _api.get(ApiConfig.questionsEndpoint))
        .where((q) => q['active'] == null || asBool(q['active']))
        .map((q) => DailyQuestion(
              id: asInt(q['id']),
              prompt: asString(q['questions'] ?? q['question']),
              correctAnswer: asString(q['correct_answer']),
            ))
        .where((q) => q.prompt.isNotEmpty)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (all.isEmpty) return const [];

    final t = now ?? DateTime.now();
    final day = DateTime(t.year, t.month, t.day);
    final dayIndex = day.difference(DateTime(2024)).inDays;
    final picked = <DailyQuestion>[];
    for (var i = 0; i < perDay && i < all.length; i++) {
      picked.add(all[(dayIndex * perDay + i) % all.length]);
    }

    final withOptions = <DailyQuestion>[];
    for (final q in picked) {
      final options = asMapList(await _api.get(ApiConfig.questionOptions(q.id)))
          .map((o) => asString(o['option_text'] ?? o['text']))
          .where((o) => o.isNotEmpty)
          .toList();
      withOptions.add(q.withOptions(options));
    }
    return withOptions;
  }

  Future<Set<String>> answeredDays() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_answeredKey) ?? const []).toSet();
  }

  Future<bool> answeredToday([DateTime? now]) async => (await answeredDays()).contains(apiDate(now ?? DateTime.now()));

  Future<void> markAnsweredToday([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    final days = (prefs.getStringList(_answeredKey) ?? <String>[]).toSet()..add(apiDate(now ?? DateTime.now()));
    final recent = days.toList()..sort();
    await prefs.setStringList(_answeredKey, recent.length > 60 ? recent.sublist(recent.length - 60) : recent);
  }
}
