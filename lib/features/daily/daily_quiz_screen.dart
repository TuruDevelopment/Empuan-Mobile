import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/daily_quiz_repository.dart';
import '../../ui/em_ui.dart';
import '../auth/form_motion.dart';

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
      body: EmStateSwitcher(
        stateKey: _loading
            ? 'loading'
            : _error != null
                ? 'error'
                : _questions.isEmpty
                    ? 'empty'
                    : _done
                        ? 'done'
                        : 'questions',
        child: _loading
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
                        // Each new question slides in from the right.
                        : AnimatedSwitcher(
                            duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.slow,
                            transitionBuilder: sharedAxisTransition(currentKey: ValueKey(question!.id)),
                            child: _QuestionView(
                              key: ValueKey(question.id),
                              question: question,
                              fromProgress: _index / _questions.length,
                              progress: (_index + 1) / _questions.length,
                              answer: _answers[question.id],
                              onAnswer: (a) => setState(() => _answers[question.id] = a),
                            ),
                          ),
      ),
      bottomNavigationBar: _loading || _error != null || _questions.isEmpty
          ? null
          : EmBottomBar(
              bordered: false,
              child: _done
                  ? EmButton(label: 'Back to Home', onPressed: () => Navigator.of(context).pop())
                  : AnimatedEnabled(
                      enabled: _answers.containsKey(question!.id),
                      child: EmButton(
                        label: _index < _questions.length - 1 ? 'Next question' : 'See results',
                        onPressed: _answers.containsKey(question.id) ? _next : null,
                      ),
                    ),
            ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.question,
    required this.fromProgress,
    required this.progress,
    required this.answer,
    required this.onAnswer,
  });

  final DailyQuestion question;

  /// Where the progress bar was on the previous question; it grows from here.
  final double fromProgress;
  final double progress;
  final String? answer;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final answered = answer != null;
    final correct = answered && question.isCorrect(answer!);
    final reduced = EmMotion.reduced(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduced ? progress : fromProgress, end: progress),
          duration: EmMotion.slow,
          curve: EmMotion.enter,
          builder: (_, value, __) => EmProgressBar(value: value),
        ),
        const SizedBox(height: 20),
        StaggerItem(index: 0, child: Text(question.prompt, style: text.headlineMedium)),
        const SizedBox(height: 20),
        for (final (i, option) in question.options.indexed) ...[
          StaggerItem(
            index: i + 1,
            child: _AnswerOption(
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
          ),
          const SizedBox(height: 10),
        ],
        // Always in the list (empty until answered) so the rows above keep
        // their place and don't replay their entrance.
        AnimatedReveal(
          offset: const Offset(0, 0.25),
          child: !answered
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Semantics(
                    liveRegion: true,
                    child: EmNote(
                      icon: correct ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      child: Text(correct ? 'Correct. Nicely done.' : 'Not quite. The answer is ${question.correctAnswer}.'),
                    ),
                  ),
                ),
        ),
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
    final reduced = EmMotion.reduced(context);
    final duration = reduced ? Duration.zero : EmMotion.medium;
    return Semantics(
      button: onTap != null,
      label: trailing == null ? label : '$label, ${trailing.$2}',
      // Colours ease into the right/wrong state instead of snapping.
      child: AnimatedContainer(
        duration: duration,
        curve: EmMotion.enter,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
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
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          curve: EmMotion.enter,
                          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
                          child: Text(label),
                        ),
                      ),
                      if (trailing != null) ...[
                        // Pops in once, when the answer is revealed.
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: reduced ? 1 : 0.4, end: 1),
                          duration: EmMotion.slow,
                          curve: EmMotion.pop,
                          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                          child: Icon(trailing.$1, size: 18, color: fg),
                        ),
                        const SizedBox(width: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: reduced ? 1 : 0, end: 1),
                          duration: duration,
                          curve: EmMotion.enter,
                          builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
                          child: Text(trailing.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                        ),
                      ],
                    ],
                  ),
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
    final reduced = EmMotion.reduced(context);
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
            // Score circle pops in while the number counts up to the result.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0.7, end: 1),
              duration: EmMotion.slow,
              curve: EmMotion.pop,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
                child: Semantics(
                  label: '$right/${questions.length}',
                  child: ExcludeSemantics(
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(begin: reduced ? right : 0, end: right),
                      duration: EmMotion.slow,
                      curve: EmMotion.enter,
                      builder: (_, n, __) => Text('$n/${questions.length}', style: text.headlineLarge?.copyWith(fontSize: 40, color: AppColors.primary)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            EmFadeSlideIn(index: 2, child: Text(title, textAlign: TextAlign.center, style: text.headlineMedium)),
            const SizedBox(height: 8),
            EmFadeSlideIn(
              index: 3,
              child: Text('New questions tomorrow.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
