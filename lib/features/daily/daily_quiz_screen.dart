import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/daily_quiz_repository.dart';
import '../../ui/em_ui.dart';

/// Today's questions: pick an answer, see right away whether it's correct,
/// then move on. A short summary closes the set.
class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  final _repo = DailyQuizRepository();
  List<DailyQuestion> _questions = const [];
  final Map<int, String> _answers = {};
  int _index = 0;
  bool _loading = true;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _questions = await _repo.today();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    await _repo.markAnsweredToday();
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions.isEmpty || _done ? null : _questions[_index];
    return Scaffold(
      appBar: EmTopBar(
        closeIcon: true,
        title: _done || _questions.isEmpty ? null : 'Today’s questions · ${_index + 1} of ${_questions.length}',
      ),
      body: _loading
          ? const EmLoading()
          : _error != null
              ? Center(child: EmStateView.error(message: _error!, onRetry: _load))
              : _questions.isEmpty
                  ? const Center(
                      child: EmStateView(
                        icon: Icons.quiz_outlined,
                        title: 'No questions today',
                        message: 'Check back tomorrow for new ones.',
                      ),
                    )
                  : _done
                      ? _Summary(questions: _questions, answers: _answers)
                      : _QuestionView(
                          key: ValueKey(question!.id),
                          question: question,
                          progress: (_index + 1) / _questions.length,
                          answer: _answers[question.id],
                          onAnswer: (a) => setState(() => _answers[question.id] = a),
                        ),
      bottomNavigationBar: _loading || _error != null || _questions.isEmpty
          ? null
          : EmBottomBar(
              bordered: false,
              child: _done
                  ? EmButton(label: 'Back to Home', onPressed: () => Navigator.of(context).pop())
                  : EmButton(
                      label: _index < _questions.length - 1 ? 'Next question' : 'See results',
                      onPressed: _answers.containsKey(question!.id) ? _next : null,
                    ),
            ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({super.key, required this.question, required this.progress, required this.answer, required this.onAnswer});

  final DailyQuestion question;
  final double progress;
  final String? answer;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final answered = answer != null;
    final correct = answered && question.isCorrect(answer!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        EmProgressBar(value: progress),
        const SizedBox(height: 20),
        Text(question.prompt, style: text.headlineMedium),
        const SizedBox(height: 20),
        for (final option in question.options) ...[
          _AnswerOption(
            label: option,
            state: !answered
                ? _OptionState.idle
                : question.isCorrect(option)
                    ? _OptionState.correct
                    : option == answer
                        ? _OptionState.wrong
                        : _OptionState.faded,
            onTap: answered ? null : () => onAnswer(option),
          ),
          const SizedBox(height: 10),
        ],
        if (answered) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: EmNote(
              icon: correct ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
              child: Text(correct ? 'Correct. Nicely done.' : 'Not quite. The answer is ${question.correctAnswer}.'),
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, faded }

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({required this.label, required this.state, this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, bg, fg, trailing) = switch (state) {
      _OptionState.idle => (AppColors.line2, AppColors.surface, AppColors.textPrimary, null),
      _OptionState.correct => (AppColors.primary, AppColors.blush, AppColors.primaryVariant, (Icons.check_rounded, 'Correct')),
      _OptionState.wrong => (AppColors.danger, AppColors.dangerTint, AppColors.danger, (Icons.close_rounded, 'Your answer')),
      _OptionState.faded => (AppColors.line2, AppColors.surface, AppColors.textSecondary, null),
    };
    return Semantics(
      button: onTap != null,
      label: trailing == null ? label : '$label, ${trailing.$2}',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg))),
                    if (trailing != null) ...[
                      Icon(trailing.$1, size: 18, color: fg),
                      const SizedBox(width: 4),
                      Text(trailing.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.questions, required this.answers});

  final List<DailyQuestion> questions;
  final Map<int, String> answers;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final right = questions.where((q) => answers[q.id] != null && q.isCorrect(answers[q.id]!)).length;
    final title = right == questions.length
        ? (questions.length == 1 ? 'Right today' : 'All right today')
        : right == 0
            ? 'Tomorrow’s another go'
            : '$right of ${questions.length} right today';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
              child: Text('$right/${questions.length}', style: text.headlineLarge?.copyWith(fontSize: 40, color: AppColors.primary)),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text('New questions tomorrow.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
