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
            child: EntranceFade(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan your next move',
                      style: AppTextStyles.heading1(textColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Tell our AI your target role and it\'ll map out the '
                    'skills, milestones, and resources to get there.',
                    style:
                        AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      labelText: 'Career goal',
                      hintText: 'e.g. Backend Developer at a fintech startup',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Generate Roadmap',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isGenerating,
                    onPressed: _isGenerating ? null : _generate,
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
            children: requiredSkills
                .map((s) => Chip(
                      label: Text(s),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                    ))
                .toList(),
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

class _Timeline extends StatelessWidget {
  final List<String> steps;
  const _Timeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Column(
      children: List.generate(steps.length, (index) {
        final isLast = index == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (!isLast)
                    Expanded(
                        child: Container(
                            width: 2, color: primary.withOpacity(0.25))),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  child: Text(steps[index],
                      style: AppTextStyles.bodyMedium(textColor)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
