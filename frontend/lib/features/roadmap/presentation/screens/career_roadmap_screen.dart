import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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

class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  final _goalController = TextEditingController();
  bool _isGenerating = false;
  bool _featurePending = false;
  Map<String, dynamic>? _roadmap;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      FeedbackManager.warning(context, 'Enter a career goal to continue');
      return;
    }

    setState(() {
      _isGenerating = true;
      _featurePending = false;
    });

    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        ApiPaths.careerRoadmap,
        data: {'careerGoal': goal},
      );
      if (!mounted) return;
      setState(() => _roadmap = response.data);
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
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: AppBar(title: const Text('Career Roadmap')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntranceFade(
                  child: Text('Plan your next move',
                      style: AppTextStyles.heading1(textColor)),
                ),
                const SizedBox(height: 8),
                EntranceFade(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Tell our AI your target role and it\'ll map out the '
                    'skills, milestones, and resources to get there.',
                    style: AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                  ),
                ),
                const SizedBox(height: 24),
                EntranceFade(
                  delay: const Duration(milliseconds: 140),
                  child: TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      labelText: 'Career goal',
                      hintText: 'e.g. Backend Developer at a fintech startup',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                const SizedBox(height: 20),
                EntranceFade(
                  delay: const Duration(milliseconds: 200),
                  child: CustomButton(
                    label: 'Generate Roadmap',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isGenerating,
                    onPressed: _isGenerating ? null : _generate,
                  ),
                ),
                if (_featurePending) ...[
                  const SizedBox(height: 32),
                  AiComingSoon(
                      feature: 'Career roadmap generation',
                      onRetry: _generate),
                ],
                if (_roadmap != null) ...[
                  const SizedBox(height: 32),
                  _RoadmapView(roadmap: _roadmap!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoadmapView extends StatelessWidget {
  final Map<String, dynamic> roadmap;
  const _RoadmapView({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final title = roadmap['title'] as String? ?? 'Your roadmap';
    final description = roadmap['description'] as String? ?? '';
    final requiredSkills =
        (roadmap['requiredSkills'] as List?)?.cast<String>() ?? [];
    final steps = (roadmap['steps'] as List?)?.cast<String>() ?? [];
    final resources = (roadmap['resources'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading1(textColor)),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(description,
              style: AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
        ],
        if (requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < requiredSkills.length; i++)
                _AnimatedChip(label: requiredSkills[i], index: i),
            ],
          ),
        ],
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Milestones', style: AppTextStyles.heading2(textColor)),
          const SizedBox(height: 16),
          _Timeline(steps: steps),
        ],
        if (resources.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.learningResources),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('View learning resources'),
          ),
        ],
      ],
    );
  }
}

class _AnimatedChip extends StatelessWidget {
  final String label;
  final int index;
  const _AnimatedChip({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index * 40),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: value.clamp(0.0, 1.2), child: child),
      ),
      child: Chip(
        label: Text(label),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        side: BorderSide.none,
      ),
    );
  }
}

/// Milestone timeline — tap a node to mark it complete (local UI state only,
/// not persisted; there's no roadmap-progress backend to save it to yet).
/// Gives the "achievement badge" / "interactive cards" feel the redesign
/// directive calls for on this screen without inventing new backend scope.
class _Timeline extends StatefulWidget {
  final List<String> steps;
  const _Timeline({required this.steps});

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  final Set<int> _completed = {};

  void _toggle(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_completed.contains(index)) {
        _completed.remove(index);
      } else {
        _completed.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressSummary(completed: _completed.length, total: widget.steps.length),
        const SizedBox(height: 20),
        ...List.generate(widget.steps.length, (index) {
          final isLast = index == widget.steps.length - 1;
          final isDone = _completed.contains(index);
          return EntranceFade(
            delay: Duration(milliseconds: index * 90),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _toggle(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: isDone
                                ? AppColors.successGradient
                                : AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: isDone
                                ? AppShadows.glow(AppColors.successDark, opacity: 0.35)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) => ScaleTransition(
                                scale: anim,
                                child: FadeTransition(opacity: anim, child: child)),
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    key: ValueKey('done'),
                                    color: Colors.white,
                                    size: 16)
                                : Text('${index + 1}',
                                    key: const ValueKey('num'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                            child: Container(
                                width: 2,
                                color: (isDone ? AppColors.successDark : primary)
                                    .withOpacity(0.25))),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 4),
                      child: GestureDetector(
                        onTap: () => _toggle(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.successDark.withOpacity(0.08)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.soft(Theme.of(context).brightness),
                          ),
                          child: Text(
                            widget.steps[index],
                            style: AppTextStyles.bodyMedium(textColor).copyWith(
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isDone
                                  ? Theme.of(context).hintColor
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int completed;
  final int total;
  const _ProgressSummary({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : completed / total;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$completed of $total complete',
                    style: AppTextStyles.title(textColor)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.successDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction * 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text('${value.round()}%',
                style: AppTextStyles.heading1(AppColors.successDark)),
          ),
        ],
      ),
    );
  }
}
