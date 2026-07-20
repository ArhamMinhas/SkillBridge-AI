import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

enum _Stage { setup, interviewing, finished }

class AiMockInterviewScreen extends StatefulWidget {
  const AiMockInterviewScreen({super.key});

  @override
  State<AiMockInterviewScreen> createState() => _AiMockInterviewScreenState();
}

class _AiMockInterviewScreenState extends State<AiMockInterviewScreen> {
  final _careerPathController = TextEditingController();
  final _answerController = TextEditingController();

  _Stage _stage = _Stage.setup;
  bool _isBusy = false;
  bool _featurePending = false;
  int _questionCount = 5;

  String? _interviewId;
  List<String> _questions = [];
  int _currentQuestion = 0;

  @override
  void dispose() {
    _careerPathController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    final careerPath = _careerPathController.text.trim();
    if (careerPath.isEmpty) {
      FeedbackManager.warning(context, 'Enter a role to practice for');
      return;
    }

    setState(() {
      _isBusy = true;
      _featurePending = false;
    });

    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiPaths.interviewQuestions,
        data: {'careerPath': careerPath, 'count': _questionCount},
      );
      final data = response.data ?? {};
      final questions = (data['questions'] as List?)?.cast<String>() ?? [];
      if (!mounted) return;
      setState(() {
        _interviewId = data['interviewId'] as String?;
        _questions = questions;
        _currentQuestion = 0;
        _stage = questions.isEmpty ? _Stage.setup : _Stage.interviewing;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (isFeaturePending(e.statusCode)) {
        setState(() => _featurePending = true);
      } else {
        FeedbackManager.error(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(context, 'Something went wrong. Please try again');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      FeedbackManager.warning(context, 'Write an answer before continuing');
      return;
    }

    setState(() => _isBusy = true);
    try {
      if (_interviewId != null) {
        await ApiClient.instance.post(
          ApiPaths.mockInterviewAnswer,
          data: {
            'interviewId': _interviewId,
            'questionIndex': _currentQuestion,
            'answerText': answer,
          },
        );
      }
      if (!mounted) return;
      _answerController.clear();
      if (_currentQuestion == _questions.length - 1) {
        setState(() => _stage = _Stage.finished);
      } else {
        setState(() => _currentQuestion++);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      FeedbackManager.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(context, 'Something went wrong. Please try again');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _reset() {
    setState(() {
      _stage = _Stage.setup;
      _questions = [];
      _interviewId = null;
      _currentQuestion = 0;
      _featurePending = false;
      _careerPathController.clear();
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Interview')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: switch (_stage) {
                _Stage.setup => _SetupView(
                    careerPathController: _careerPathController,
                    count: _questionCount,
                    onCountChanged: (v) => setState(() => _questionCount = v),
                    isBusy: _isBusy,
                    onStart: _startInterview,
                    featurePending: _featurePending,
                    onRetry: _startInterview,
                  ),
                _Stage.interviewing => _InterviewView(
                    question: _questions[_currentQuestion],
                    questionNumber: _currentQuestion + 1,
                    totalQuestions: _questions.length,
                    answerController: _answerController,
                    isBusy: _isBusy,
                    onSubmit: _submitAnswer,
                  ),
                _Stage.finished => _FinishedView(onRestart: _reset),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  final TextEditingController careerPathController;
  final int count;
  final ValueChanged<int> onCountChanged;
  final bool isBusy;
  final VoidCallback onStart;
  final bool featurePending;
  final VoidCallback onRetry;

  const _SetupView({
    required this.careerPathController,
    required this.count,
    required this.onCountChanged,
    required this.isBusy,
    required this.onStart,
    required this.featurePending,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Practice makes confident',
            style: AppTextStyles.heading1(textColor)),
        const SizedBox(height: 8),
        Text(
          'Tell us the role you\'re targeting — our AI interviewer will ask '
          'relevant questions and give feedback on your answers.',
          style: AppTextStyles.bodyMedium(Theme.of(context).hintColor),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: careerPathController,
          decoration: const InputDecoration(
            labelText: 'Role to practice for',
            hintText: 'e.g. Frontend Developer',
            prefixIcon: Icon(Icons.work_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        Text('Number of questions', style: AppTextStyles.heading2(textColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [3, 5, 8].map((n) {
            final selected = n == count;
            return ChoiceChip(
              label: Text('$n'),
              selected: selected,
              onSelected: (_) => onCountChanged(n),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        CustomButton(
          label: 'Start Interview',
          icon: Icons.play_arrow_rounded,
          isLoading: isBusy,
          onPressed: isBusy ? null : onStart,
        ),
        if (featurePending) ...[
          const SizedBox(height: 32),
          AiComingSoon(feature: 'AI mock interviews', onRetry: onRetry),
        ],
      ],
    );
  }
}

class _InterviewView extends StatelessWidget {
  final String question;
  final int questionNumber;
  final int totalQuestions;
  final TextEditingController answerController;
  final bool isBusy;
  final VoidCallback onSubmit;

  const _InterviewView({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.answerController,
    required this.isBusy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = questionNumber / totalQuestions;
    final isLast = questionNumber == totalQuestions;

    return Column(
      key: ValueKey(questionNumber),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Question $questionNumber of $totalQuestions',
            style: AppTextStyles.caption(Theme.of(context).hintColor)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(question,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: answerController,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Your answer',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: isLast ? 'Finish Interview' : 'Next Question',
          icon: isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
          isLoading: isBusy,
          onPressed: isBusy ? null : onSubmit,
        ),
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  final VoidCallback onRestart;
  const _FinishedView({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            gradient: AppColors.successGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 44),
        ),
        const SizedBox(height: 24),
        Text('Interview complete!', style: AppTextStyles.heading1(textColor)),
        const SizedBox(height: 8),
        Text(
          'Nice work. Your answers have been recorded — feedback will '
          'appear here once available.',
          style: AppTextStyles.bodyMedium(Theme.of(context).hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        CustomButton(
          label: 'Practice Again',
          variant: ButtonVariant.outline,
          onPressed: onRestart,
        ),
      ],
    );
  }
}
