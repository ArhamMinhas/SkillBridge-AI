import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

const _proficiencyLabels = [
  'Beginner',
  'Novice',
  'Intermediate',
  'Advanced',
  'Expert'
];

class SkillAssessmentScreen extends StatefulWidget {
  const SkillAssessmentScreen({super.key});

  @override
  State<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends State<SkillAssessmentScreen> {
  final _skillInputController = TextEditingController();
  final Map<String, int> _ratings = {};
  bool _isSubmitting = false;
  bool _featurePending = false;

  @override
  void dispose() {
    _skillInputController.dispose();
    super.dispose();
  }

  void _addSkill(String raw) {
    final skill = raw.trim();
    if (skill.isEmpty || _ratings.containsKey(skill)) {
      _skillInputController.clear();
      return;
    }
    setState(() => _ratings[skill] = 3);
    _skillInputController.clear();
  }

  void _removeSkill(String skill) => setState(() => _ratings.remove(skill));

  Future<void> _submit() async {
    if (_ratings.isEmpty) {
      FeedbackManager.warning(context, 'Add at least one skill to assess');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _featurePending = false;
    });

    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiPaths.weakSkills,
        data: {
          'assessmentAnswers': _ratings,
          'jobRequiredSkills': <String>[],
        },
      );
      if (!mounted) return;
      context.push(AppRoutes.skillGapReport, extra: response.data);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Assessment')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate your skills',
                      style: AppTextStyles.heading1(textColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Add your skills and rate your proficiency honestly — '
                    'this powers your personalized skill gap report.',
                    style:
                        AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillInputController,
                          decoration: const InputDecoration(
                            labelText: 'e.g. Python, SQL, React',
                            prefixIcon: Icon(Icons.add_circle_outline_rounded),
                          ),
                          onSubmitted: _addSkill,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _addSkill(_skillInputController.text),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_ratings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No skills added yet.',
                        style: AppTextStyles.bodyMedium(
                            Theme.of(context).hintColor),
                      ),
                    )
                  else
                    ..._ratings.keys.map((skill) => _SkillRatingTile(
                          skill: skill,
                          rating: _ratings[skill]!,
                          onChanged: (v) => setState(() => _ratings[skill] = v),
                          onRemove: () => _removeSkill(skill),
                        )),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Get My Skill Gap Report',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  if (_featurePending) ...[
                    const SizedBox(height: 32),
                    AiComingSoon(
                        feature: 'Skill gap analysis', onRetry: _submit),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillRatingTile extends StatelessWidget {
  final String skill;
  final int rating;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  const _SkillRatingTile({
    required this.skill,
    required this.rating,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(skill,
                    style: AppTextStyles.bodyLarge(textColor)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(_proficiencyLabels[rating - 1],
                  style: AppTextStyles.caption(primary)
                      .copyWith(fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Slider(
            value: rating.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _proficiencyLabels[rating - 1],
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
