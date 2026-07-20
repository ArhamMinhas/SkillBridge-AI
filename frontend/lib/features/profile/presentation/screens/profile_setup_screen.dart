import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

enum ExperienceLevel { junior, mid, senior }

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();

  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Step 1
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  ExperienceLevel? _experienceLevel;

  // Step 2
  final _skillInputController = TextEditingController();
  final List<String> _skills = [];

  // Step 3
  final _targetRoleController = TextEditingController();
  final _industryController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _skillInputController.dispose();
    _targetRoleController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _totalSteps - 1;

  void _addSkill(String raw) {
    final skill = raw.trim();
    if (skill.isEmpty) return;
    if (_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
      _skillInputController.clear();
      return;
    }
    setState(() => _skills.add(skill));
    _skillInputController.clear();
  }

  void _removeSkill(String skill) => setState(() => _skills.remove(skill));

  void _goNext() {
    if (_currentStep == 0 && !_step1FormKey.currentState!.validate()) return;
    if (_currentStep == 1 && _skills.isEmpty) {
      FeedbackManager.warning(context, 'Add at least one skill to continue');
      return;
    }

    if (_isLastStep) {
      _submit();
      return;
    }

    setState(() => _currentStep++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _submit() async {
    if (_targetRoleController.text.trim().isEmpty) {
      FeedbackManager.warning(context, 'Enter a target role to finish');
      return;
    }

    if (!FirebaseStatus.isAvailable) {
      FeedbackManager.warning(
          context, 'Firebase isn\'t configured yet — profile can\'t be saved');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final industry = _industryController.text.trim();
      final careerGoal = industry.isEmpty
          ? _targetRoleController.text.trim()
          : '${_targetRoleController.text.trim()} in $industry';

      await ApiClient.instance.put(ApiPaths.userProfile, data: {
        'education': _universityController.text.trim(),
        'degree': _degreeController.text.trim(),
        'experienceLevel': _experienceLevel?.name,
        'skills': _skills,
        'careerGoal': careerGoal,
      });

      if (!mounted) return;
      FeedbackManager.success(context, 'Profile updated successfully');
      context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      if (!mounted) return;
      FeedbackManager.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(
          context, 'Network unavailable. Check your connection');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _StepProgressBar(
                currentStep: _currentStep, totalSteps: _totalSteps),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ResponsiveCenter(
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: CustomButton(
                          label: 'Back',
                          variant: ButtonVariant.outline,
                          onPressed: _isSubmitting ? null : _goBack,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: CustomButton(
                        label: _isLastStep ? 'Finish' : 'Continue',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _goNext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ResponsiveCenter(
        child: EntranceFade(
          child: Form(
            key: _step1FormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal info', style: AppTextStyles.heading1(textColor)),
                const SizedBox(height: 8),
                Text('Tell us about your education and experience',
                    style:
                        AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(
                    labelText: 'University / College',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (v) => Validators.required(v, label: 'University'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(
                    labelText: 'Degree',
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                  ),
                  validator: (v) => Validators.required(v, label: 'Degree'),
                ),
                const SizedBox(height: 24),
                Text('Experience level',
                    style: AppTextStyles.heading2(textColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: ExperienceLevel.values.map((level) {
                    final selected = _experienceLevel == level;
                    return ChoiceChip(
                      label: Text(_experienceLevelLabel(level)),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _experienceLevel = level),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ResponsiveCenter(
        child: EntranceFade(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Technical skills',
                  style: AppTextStyles.heading1(textColor)),
              const SizedBox(height: 8),
              Text('Add skills one at a time — press enter or tap add',
                  style: AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillInputController,
                      decoration: const InputDecoration(
                        labelText: 'e.g. Flutter, Python, SQL',
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
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills
                    .map((skill) => TweenAnimationBuilder<double>(
                          key: ValueKey(skill),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Transform.scale(
                            scale: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                          child: Chip(
                            label: Text(skill),
                            onDeleted: () => _removeSkill(skill),
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ResponsiveCenter(
        child: EntranceFade(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Career goals', style: AppTextStyles.heading1(textColor)),
              const SizedBox(height: 8),
              Text('What role are you aiming for?',
                  style: AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
              const SizedBox(height: 24),
              TextField(
                controller: _targetRoleController,
                decoration: const InputDecoration(
                  labelText: 'Target role',
                  hintText: 'e.g. Junior Backend Developer',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: 'Desired industry (optional)',
                  hintText: 'e.g. Fintech',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _experienceLevelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.junior:
        return 'Junior';
      case ExperienceLevel.mid:
        return 'Mid';
      case ExperienceLevel.senior:
        return 'Senior';
    }
  }
}

/// Horizontal step progress indicator — fills left to right as [currentStep]
/// advances, per docs/frontend_design_spec.md screen 6.
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}
