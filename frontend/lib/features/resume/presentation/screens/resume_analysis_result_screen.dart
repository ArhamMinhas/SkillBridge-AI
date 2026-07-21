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
                  child: EntranceFade(
                    child: EmptyState(
                      icon: Icons.fact_check_rounded,
                      title: 'No report yet',
                      message: 'Upload a resume to see your ATS score and '
                          'personalized suggestions here.',
                      actionLabel: 'Upload resume',
                      onAction: () => context.go(AppRoutes.resumeUpload),
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ResponsiveCenter(
                  child: _ResultBody(result: result!),
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
        EntranceFade(
          child: Center(
            child: _ScoreGauge(
              score: atsScore,
              strengthCount: strengths.length,
              weaknessCount: weaknesses.length,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (strengths.isNotEmpty)
          EntranceFade(
            delay: const Duration(milliseconds: 120),
            child: _ExpandableSection(
              title: 'Strengths',
              icon: Icons.check_circle_rounded,
              color: AppColors.successDark,
              items: strengths,
            ),
          ),
        if (weaknesses.isNotEmpty)
          EntranceFade(
            delay: const Duration(milliseconds: 200),
            child: _ExpandableSection(
              title: 'Weaknesses',
              icon: Icons.warning_rounded,
              color: AppColors.warningDark,
              items: weaknesses,
            ),
          ),
        if (missingSkills.isNotEmpty) ...[
          EntranceFade(
            delay: const Duration(milliseconds: 280),
            child: Text('Missing Skills',
                style: AppTextStyles.heading2(
                    Theme.of(context).textTheme.bodyLarge!.color!)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < missingSkills.length; i++)
                _AnimatedChip(
                  label: missingSkills[i],
                  color: AppColors.errorDark,
                  index: i,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (suggestions.isNotEmpty)
          EntranceFade(
            delay: const Duration(milliseconds: 360),
            child: _ExpandableSection(
              title: 'Suggestions',
              icon: Icons.lightbulb_rounded,
              color: Theme.of(context).primaryColor,
              items: suggestions,
            ),
          ),
      ],
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final int score;
  final int strengthCount;
  final int weaknessCount;

  const _ScoreGauge({
    required this.score,
    required this.strengthCount,
    required this.weaknessCount,
  });

  Color _color() {
    if (score >= 75) return AppColors.successDark;
    if (score >= 50) return AppColors.warningDark;
    return AppColors.errorDark;
  }

  String _tier() {
    if (score >= 75) return 'Strong ATS match';
    if (score >= 50) return 'Needs a few tweaks';
    return 'Needs improvement';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, entrance, child) =>
          Transform.scale(scale: entrance, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glow(color, opacity: 0.28),
                      ),
                    ),
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
          ),
          const SizedBox(height: 12),
          Text(_tier(),
              style: AppTextStyles.title(
                  Theme.of(context).textTheme.bodyLarge!.color!)),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScorePill(
                  icon: Icons.check_circle_rounded,
                  label: '$strengthCount strength${strengthCount == 1 ? '' : 's'}',
                  color: AppColors.successDark),
              const SizedBox(width: 10),
              _ScorePill(
                  icon: Icons.warning_rounded,
                  label: '$weaknessCount to improve',
                  color: AppColors.warningDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ScorePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption(color)),
        ],
      ),
    );
  }
}

class _AnimatedChip extends StatelessWidget {
  final String label;
  final Color color;
  final int index;

  const _AnimatedChip({required this.label, required this.color, required this.index});

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
        backgroundColor: color.withOpacity(0.1),
        labelStyle: TextStyle(color: color),
        side: BorderSide.none,
      ),
    );
  }
}

/// Elevated, expandable card replacing the original plain icon+text rows —
/// defaults open so the value is visible immediately, but collapses to
/// declutter a long report.
class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Icon(widget.icon, color: widget.color, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(widget.title,
                        style: AppTextStyles.heading2(textColor)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('${widget.items.length}',
                        style: AppTextStyles.caption(widget.color)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(widget.icon,
                                        color: widget.color, size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(item,
                                            style:
                                                AppTextStyles.bodyMedium(textColor))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
