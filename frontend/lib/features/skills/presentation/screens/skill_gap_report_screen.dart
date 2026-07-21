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
                  child: EntranceFade(
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
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ResponsiveCenter(
                  child: _ReportBody(report: report!),
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
        EntranceFade(
          child: _SummaryHeader(
            weakCount: weakSkills.length,
            recommendationCount: recommendations.length,
          ),
        ),
        const SizedBox(height: 28),
        if (weakSkills.isNotEmpty) ...[
          EntranceFade(
            delay: const Duration(milliseconds: 100),
            child: Text('Skills to strengthen',
                style: AppTextStyles.heading2(textColor)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < weakSkills.length; i++)
                _GapChip(skill: weakSkills[i], index: i),
            ],
          ),
          const SizedBox(height: 28),
        ],
        if (recommendations.isNotEmpty) ...[
          EntranceFade(
            delay: const Duration(milliseconds: 180),
            child: Text('Recommended next steps',
                style: AppTextStyles.heading2(textColor)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < recommendations.length; i++)
            _RecommendationCard(text: recommendations[i], index: i),
        ],
      ],
    );
  }
}

/// Gradient hero card summarizing the report at a glance — replaces the
/// original screen's plain "Where to focus" heading with an actual visual
/// anchor, matching the redesign directive's hero-card treatment.
class _SummaryHeader extends StatelessWidget {
  final int weakCount;
  final int recommendationCount;

  const _SummaryHeader({
    required this.weakCount,
    required this.recommendationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.glow(AppColors.primaryDark, opacity: 0.25),
      ),
      child: Row(
        children: [
          const _PulsingRadar(),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where to focus',
                    style: AppTextStyles.heading1(Colors.white)),
                const SizedBox(height: 6),
                Text(
                  weakCount == 0
                      ? 'No gaps detected — nice work!'
                      : '$weakCount skill${weakCount == 1 ? '' : 's'} to '
                          'strengthen · $recommendationCount next '
                          'step${recommendationCount == 1 ? '' : 's'}',
                  style:
                      AppTextStyles.bodyMedium(Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRadar extends StatefulWidget {
  const _PulsingRadar();

  @override
  State<_PulsingRadar> createState() => _PulsingRadarState();
}

class _PulsingRadarState extends State<_PulsingRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 1.0 + _controller.value * 0.12;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded,
                  color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _GapChip extends StatelessWidget {
  final String skill;
  final int index;

  const _GapChip({required this.skill, required this.index});

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
        avatar: const Icon(Icons.trending_up_rounded,
            size: 16, color: AppColors.warningDark),
        label: Text(skill),
        backgroundColor: AppColors.warningDark.withOpacity(0.1),
        side: BorderSide.none,
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String text;
  final int index;

  const _RecommendationCard({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, (1 - value.clamp(0.0, 1.0)) * 14), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft(Theme.of(context).brightness),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(text, style: AppTextStyles.bodyMedium(textColor))),
          ],
        ),
      ),
    );
  }
}
