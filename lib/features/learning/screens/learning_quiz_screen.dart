import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';

class LearningQuizScreen extends StatefulWidget {
  const LearningQuizScreen({
    super.key,
    required this.lessonId,
    required this.service,
  });

  final int lessonId;
  final LearningService service;

  @override
  State<LearningQuizScreen> createState() => _LearningQuizScreenState();
}

class _LearningQuizScreenState extends State<LearningQuizScreen> {
  late Future<LearningQuiz> _quizFuture;
  final Map<int, String> _answers = {};
  LearningQuizAttempt? _attempt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quizFuture = widget.service.getQuiz(widget.lessonId);
  }

  Future<void> _reload() async {
    setState(() {
      _attempt = null;
      _answers.clear();
      _quizFuture = widget.service.getQuiz(widget.lessonId);
    });
    await _quizFuture;
  }

  Future<void> _submit(LearningQuiz quiz) async {
    if (_answers.length != quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Answer all questions before submitting.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final attempt = await widget.service.submitQuiz(quiz.id, _answers);
      if (!mounted) return;
      setState(() => _attempt = attempt);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quiz')),
      body: FutureBuilder<LearningQuiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return LearningErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final quiz = snapshot.requireData;
          if (_attempt != null) {
            return _QuizResultView(
              attempt: _attempt!,
              onTryAgain: quiz.canAttempt ? _reload : null,
              onDone: () => Navigator.pop(context, _attempt!.passed),
            );
          }

          return _QuizForm(
            quiz: quiz,
            answers: _answers,
            submitting: _submitting,
            onAnswer: (questionId, answer) {
              setState(() => _answers[questionId] = answer);
            },
            onSubmit: () => _submit(quiz),
          );
        },
      ),
    );
  }
}

class _QuizForm extends StatelessWidget {
  const _QuizForm({
    required this.quiz,
    required this.answers,
    required this.submitting,
    required this.onAnswer,
    required this.onSubmit,
  });

  final LearningQuiz quiz;
  final Map<int, String> answers;
  final bool submitting;
  final void Function(int, String) onAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (quiz.instructions != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.instructions!,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Passing score ${quiz.passingScore}%'
                '${quiz.maxAttempts == null ? '' : ' • '
                    '${quiz.attemptsUsed}/${quiz.maxAttempts} attempts'}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...quiz.questions.asMap().entries.map(
              (entry) => _QuestionCard(
                number: entry.key + 1,
                question: entry.value,
                selected: answers[entry.value.id],
                onChanged: (answer) => onAnswer(entry.value.id, answer),
              ),
            ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: submitting || !quiz.canAttempt ? null : onSubmit,
          icon: submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            !quiz.canAttempt
                ? 'Attempt limit reached'
                : submitting
                    ? 'Grading answers...'
                    : 'Submit answers',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final int number;
  final LearningQuizQuestion question;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. ${question.prompt}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: Column(
                children: question.options
                    .map(
                      (option) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: option.key,
                        activeColor: AppColors.primary,
                        title: Text(
                          option.text,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({
    required this.attempt,
    required this.onDone,
    this.onTryAgain,
  });

  final LearningQuizAttempt attempt;
  final VoidCallback onDone;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: attempt.passed ? AppColors.secondary : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                attempt.passed
                    ? Icons.workspace_premium_rounded
                    : Icons.refresh_rounded,
                size: 54,
                color: attempt.passed ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                attempt.passed ? 'You passed!' : 'Not passed yet',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: attempt.passed ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${attempt.score.round()} out of 100',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: attempt.passed ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...attempt.result.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: Icon(
                  entry.value.correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: entry.value.correct
                      ? AppColors.secondary
                      : AppColors.error,
                ),
                title: Text('Question ${entry.key + 1}'),
                subtitle: Text(
                  entry.value.correct
                      ? 'Correct answer'
                      : 'Correct answer: ${entry.value.correctOptionKey}'
                          '${entry.value.explanation == null ? '' : '\n'
                              '${entry.value.explanation}'}',
                ),
              ),
            ),
        const SizedBox(height: 16),
        if (onTryAgain != null)
          OutlinedButton.icon(
            onPressed: onTryAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: onDone,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Back to lesson'),
        ),
      ],
    );
  }
}
