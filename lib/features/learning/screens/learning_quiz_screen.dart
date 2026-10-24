import 'package:flutter/material.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';

/// One question per page, then a result view. Pops with true when passed.
class LearningQuizScreen extends StatefulWidget {
  const LearningQuizScreen({super.key, required this.lessonId, this.service});

  final int lessonId;
  final LearningService? service;

  @override
  State<LearningQuizScreen> createState() => _LearningQuizScreenState();
}

class _LearningQuizScreenState extends State<LearningQuizScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  late Future<LearningQuiz> _quizFuture = _service.getQuiz(widget.lessonId);
  final Map<int, String> _answers = {};
  int _page = 0;
  bool _forward = true;
  LearningQuizAttempt? _attempt;
  LearningQuiz? _attemptedQuiz;
  bool _submitting = false;

  Future<void> _reload() async {
    final future = _service.getQuiz(widget.lessonId);
    setState(() {
      _attempt = null;
      _attemptedQuiz = null;
      _answers.clear();
      _page = 0;
      _quizFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  Future<void> _submit(LearningQuiz quiz) async {
    setState(() => _submitting = true);
    try {
      final attempt = await _service.submitQuiz(quiz.id, Map.of(_answers));
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _attemptedQuiz = quiz;
      });
    } catch (error) {
      if (mounted) showEmToast(context, '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _close() async {
    if (_attempt != null) {
      Navigator.of(context).pop(_attempt!.passed);
      return;
    }
    if (_answers.isNotEmpty) {
      final leave = await showEmConfirm(
        context,
        title: 'Leave the quiz?',
        message: 'Your answers won’t be saved, and this won’t count as an attempt.',
        confirmLabel: 'Leave',
        cancelLabel: 'Keep going',
      );
      if (!leave || !mounted) return;
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningQuiz>(
      future: _quizFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final quiz = waiting ? null : snapshot.data;
        final attempt = _attempt;

        final Widget screen;
        if (attempt != null && _attemptedQuiz != null) {
          screen = _QuizResultView(
            quiz: _attemptedQuiz!,
            attempt: attempt,
            onClose: _close,
            onTryAgain: _reload,
          );
        } else {
          screen = _questionScreen(context, snapshot, quiz, waiting);
        }
        return EmStateSwitcher(stateKey: attempt == null ? 'quiz' : 'result-${attempt.id}', child: screen);
      },
    );
  }

  Widget _questionScreen(BuildContext context, AsyncSnapshot<LearningQuiz> snapshot, LearningQuiz? quiz, bool waiting) {
    final count = quiz?.questions.length ?? 0;
    Widget body;
    Widget? bottom;
    String key = 'questions';
    if (waiting) {
      key = 'loading';
      body = const _QuizSkeleton();
    } else if (snapshot.hasError) {
      key = 'error';
      body = Center(child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload));
    } else if (count == 0) {
      key = 'empty';
      body = const Center(
        child: EmStateView(
            icon: Icons.quiz_outlined, title: 'No questions yet', message: 'This quiz doesn’t have any questions yet.'),
      );
    } else if (!quiz!.canAttempt) {
      key = 'blocked';
      body = Center(
        child: EmStateView(
          icon: Icons.block_rounded,
          title: 'No attempts left',
          message: 'You’ve used all ${quiz.maxAttempts} attempts for this quiz.',
          actionLabel: 'Back to lesson',
          onAction: () => Navigator.of(context).pop(false),
        ),
      );
    } else {
      final question = quiz.questions[_page];
      final last = _page == count - 1;
      final dx = _forward ? 0.08 : -0.08;
      body = AnimatedSwitcher(
        duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
        switchInCurve: EmMotion.enter,
        switchOutCurve: EmMotion.exit,
        transitionBuilder: (child, animation) {
          // The outgoing page drifts the opposite way to the incoming one.
          final incoming = child.key == ValueKey(question.id);
          final begin = Offset(incoming ? dx : -dx, 0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: Tween(begin: begin, end: Offset.zero).animate(animation), child: child),
          );
        },
        child: _QuestionPage(
          key: ValueKey(question.id),
          quiz: quiz,
          question: question,
          selected: _answers[question.id],
          onSelect: (key) => setState(() => _answers[question.id] = key),
        ),
      );
      bottom = EmBottomBar(
        bordered: false,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: EmButton(
                label: 'Back',
                variant: EmButtonVariant.secondary,
                onPressed: _page == 0
                    ? null
                    : () => setState(() {
                          _forward = false;
                          _page--;
                        }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EmButton(
                label: last ? 'Submit' : 'Next',
                loading: _submitting,
                onPressed: _answers[question.id] == null
                    ? null
                    : last
                        ? () => _submit(quiz)
                        : () => setState(() {
                              _forward = true;
                              _page++;
                            }),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: _answers.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: LearningProgressTopBar(
          closeLabel: 'Close quiz',
          onClose: _close,
          caption: count > 0 ? 'Question ${_page + 1} of $count' : 'Quiz',
          progress: count > 0 ? (_page + 1) / count : null,
        ),
        body: EmStateSwitcher(stateKey: key, child: body),
        bottomNavigationBar: bottom,
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage(
      {super.key, required this.quiz, required this.question, required this.selected, required this.onSelect});

  final LearningQuiz quiz;
  final LearningQuizQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final attempt = quiz.attemptsUsed + 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            EmTag('Pass with ${quiz.passingScore}%'),
            EmTag(quiz.maxAttempts == null ? 'Attempt $attempt' : 'Attempt $attempt of ${quiz.maxAttempts}'),
          ],
        ),
        const SizedBox(height: 20),
        Text(question.prompt, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EmOption(
              label: question.options[i].text,
              selected: selected == question.options[i].key,
              leading: LearningKeyBadge(_keyLabel(question.options[i].key, i),
                  selected: selected == question.options[i].key),
              onTap: () => onSelect(question.options[i].key),
            ),
          ),
      ],
    );
  }
}

String _keyLabel(String key, int index) => key.length == 1 ? key.toUpperCase() : String.fromCharCode(65 + index);

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({required this.quiz, required this.attempt, required this.onClose, required this.onTryAgain});

  final LearningQuiz quiz;
  final LearningQuizAttempt attempt;
  final VoidCallback onClose;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = attempt.result.isEmpty ? quiz.questions.length : attempt.result.length;
    final correct = attempt.result.where((r) => r.correct).length;
    final passScore = attempt.passingScore > 0 ? attempt.passingScore : quiz.passingScore;
    final attemptsLeft = quiz.maxAttempts == null ? null : (quiz.maxAttempts! - quiz.attemptsUsed - 1).clamp(0, 999);
    final canRetry = !attempt.passed && (attemptsLeft == null || attemptsLeft > 0);

    final summary = StringBuffer('$correct of $total correct. ');
    if (attempt.passed) {
      summary.write('You needed $passScore% to pass.');
    } else {
      summary.write('You need $passScore% to pass.');
      if (attemptsLeft != null) {
        summary.write(attemptsLeft == 0
            ? ' No attempts left.'
            : ' $attemptsLeft ${attemptsLeft == 1 ? 'attempt' : 'attempts'} left.');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EmTopBar(
        title: 'Quiz result',
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: EmIconButton(icon: Icons.close_rounded, label: 'Close', onPressed: onClose),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          EmCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _ResultBadge(passed: attempt.passed),
                const SizedBox(height: 12),
                Semantics(
                  label: '${attempt.score.round()} percent',
                  excludeSemantics: true,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: EmMotion.reduced(context) ? attempt.score : 0, end: attempt.score),
                    duration: const Duration(milliseconds: 700),
                    curve: EmMotion.enter,
                    builder: (_, value, __) =>
                        Text('${value.round()}%', style: text.headlineLarge?.copyWith(fontSize: 44, height: 48 / 44)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(attempt.passed ? 'You passed' : 'Almost there', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(summary.toString(), textAlign: TextAlign.center, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < attempt.result.length; i++)
            EmFadeSlideIn(
              index: i + 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResultCard(number: i + 1, result: attempt.result[i], question: _questionFor(attempt.result[i])),
              ),
            ),
        ],
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRetry) ...[EmButton(label: 'Try again', onPressed: onTryAgain), const SizedBox(height: 8)],
            EmButton(
              label: 'Back to lesson',
              variant: canRetry ? EmButtonVariant.text : EmButtonVariant.primary,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  LearningQuizQuestion? _questionFor(LearningQuizResult result) {
    for (final question in quiz.questions) {
      if (question.id == result.questionId) return question;
    }
    return null;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.number, required this.result, this.question});

  final int number;
  final LearningQuizResult result;
  final LearningQuizQuestion? question;

  String _optionText(String key) {
    for (final option in question?.options ?? const <LearningQuizOption>[]) {
      if (option.key == key) return option.text;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final ok = result.correct;
    final tone = ok ? AppColors.primary : AppColors.danger;
    return EmCard(
      borderColor: ok ? AppColors.line : AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: ok ? AppColors.primary : AppColors.dangerTint, shape: BoxShape.circle),
                child: Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                    size: 16, color: ok ? Colors.white : AppColors.danger),
              ),
              const SizedBox(width: 8),
              Text(
                'Question $number · ${ok ? 'Correct' : 'Not quite'}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: ok ? AppColors.textPrimary : AppColors.danger),
              ),
            ],
          ),
          if (question != null) ...[
            const SizedBox(height: 10),
            Text(question!.prompt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 8),
          _AnswerLine(label: 'Your answer:', value: _optionText(result.selectedOptionKey), color: tone),
          if (!ok) ...[
            const SizedBox(height: 4),
            _AnswerLine(label: 'Correct:', value: _optionText(result.correctOptionKey), color: AppColors.primary),
          ],
          if (result.explanation != null && result.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(12)),
              child: Text(result.explanation!,
                  style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.primaryVariant)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textPrimary),
    );
  }
}

/// Pass or retry icon that pops in once when the result appears.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    final reduced = EmMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0.4, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 600),
      curve: passed ? EmMotion.pop : EmMotion.enter,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: passed ? AppColors.primary : AppColors.blush, shape: BoxShape.circle),
        child: Icon(
          passed ? Icons.workspace_premium_rounded : Icons.refresh_rounded,
          color: passed ? Colors.white : AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}

class _QuizSkeleton extends StatelessWidget {
  const _QuizSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Row(children: [
            EmSkeleton(height: 24, width: 110, radius: 10),
            SizedBox(width: 8),
            EmSkeleton(height: 24, width: 110, radius: 10)
          ]),
          const SizedBox(height: 20),
          const EmSkeleton(height: 26),
          const SizedBox(height: 8),
          const EmSkeleton(height: 26, width: 200),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++) ...[const EmSkeleton(height: 56, radius: 16), const SizedBox(height: 10)],
        ],
      ),
    );
  }
}
