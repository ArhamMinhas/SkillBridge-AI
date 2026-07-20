import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

class ResumeAnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic>? result;

  const ResumeAnalysisResultScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SafeArea(
        top: false,
        child: result == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.fact_check_rounded,
                    title: 'No report yet',
                    message: 'Upload a resume to see your ATS score and '
                        'personalized suggestions here.',
                    actionLabel: 'Upload resume',
                    onAction: () => context.go(AppRoutes.resumeUpload),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ResponsiveCenter(
                  child: EntranceFade(
                    child: _ResultBody(result: result!),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final atsScore = (result['atsScore'] as num?)?.toInt() ?? 0;
    final strengths = (result['strengths'] as List?)?.cast<String>() ?? [];
    final weaknesses = (result['weaknesses'] as List?)?.cast<String>() ?? [];
    final missingSkills =
        (result['missingSkills'] as List?)?.cast<String>() ?? [];
    final suggestions = (result['suggestions'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _ScoreGauge(score: atsScore)),
        const SizedBox(height: 32),
        if (strengths.isNotEmpty)
          _ResultSection(
            title: 'Strengths',
            icon: Icons.check_circle_rounded,
            color: AppColors.successDark,
            items: strengths,
          ),
        if (weaknesses.isNotEmpty)
          _ResultSection(
            title: 'Weaknesses',
            icon: Icons.warning_rounded,
            color: AppColors.warningDark,
            items: weaknesses,
          ),
        if (missingSkills.isNotEmpty) ...[
          Text('Missing Skills',
              style: AppTextStyles.heading2(
                  Theme.of(context).textTheme.bodyLarge!.color!)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missingSkills
                .map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.errorDark.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppColors.errorDark),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (suggestions.isNotEmpty)
          _ResultSection(
            title: 'Suggestions',
            icon: Icons.lightbulb_rounded,
            color: Theme.of(context).primaryColor,
            items: suggestions,
          ),
      ],
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final int score;
  const _ScoreGauge({required this.score});

  Color _color(BuildContext context) {
    if (score >= 75) return AppColors.successDark;
    if (score >= 50) return AppColors.warningDark;
    return AppColors.errorDark;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Theme.of(context).dividerColor,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(value * 100).round()}',
                      style: AppTextStyles.display1(color)),
                  Text('ATS SCORE', style: AppTextStyles.caption(color)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2(textColor)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: AppTextStyles.bodyMedium(textColor))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
