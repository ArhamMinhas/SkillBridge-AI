import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

class SkillGapReportScreen extends StatelessWidget {
  final Map<String, dynamic>? report;

  const SkillGapReportScreen({super.key, this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Gap Report')),
      body: SafeArea(
        top: false,
        child: report == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.radar_rounded,
                    title: 'No report yet',
                    message:
                        'Complete a skill assessment to see where your gaps '
                        'are and what to learn next.',
                    actionLabel: 'Take assessment',
                    onAction: () => context.go(AppRoutes.skillAssessment),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ResponsiveCenter(
                  child: EntranceFade(child: _ReportBody(report: report!)),
                ),
              ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final weakSkills = (report['weakSkills'] as List?)?.cast<String>() ?? [];
    final recommendations =
        (report['recommendations'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where to focus', style: AppTextStyles.heading1(textColor)),
        const SizedBox(height: 8),
        Text(
          'Based on your self-assessment, these are the skills worth '
          'prioritizing next.',
          style: AppTextStyles.bodyMedium(Theme.of(context).hintColor),
        ),
        const SizedBox(height: 28),
        if (weakSkills.isEmpty && recommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No gaps detected — nice work!',
                style: AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
          ),
        if (weakSkills.isNotEmpty) ...[
          Text('Skills to strengthen',
              style: AppTextStyles.heading2(textColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weakSkills
                .map((skill) => Chip(
                      avatar: const Icon(Icons.trending_up_rounded,
                          size: 16, color: AppColors.warningDark),
                      label: Text(skill),
                      backgroundColor: AppColors.warningDark.withOpacity(0.1),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
        ],
        if (recommendations.isNotEmpty) ...[
          Text('Recommended next steps',
              style: AppTextStyles.heading2(textColor)),
          const SizedBox(height: 12),
          ...recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: Theme.of(context).primaryColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(r,
                            style: AppTextStyles.bodyMedium(textColor))),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
