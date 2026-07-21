import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class JobDetailScreen extends StatefulWidget {
  final String? jobId;

  const JobDetailScreen({super.key, this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Future<Map<String, dynamic>>? _jobFuture;
  Future<Map<String, dynamic>>? _matchFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.jobId;
    if (id != null) {
      _jobFuture = _loadJob(id);
      _matchFuture = _loadMatch(id);
    }
  }

  Future<Map<String, dynamic>> _loadJob(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiPaths.jobDetail(id));
    return response.data!;
  }

  Future<Map<String, dynamic>> _loadMatch(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiPaths.jobMatch(id));
    return response.data!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SafeArea(
        top: false,
        child: _jobFuture == null
            ? const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Job not found',
                message: 'This listing is missing an ID.',
              )
            : FutureBuilder<Map<String, dynamic>>(
                future: _jobFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        ShimmerCardSkeleton(),
                        ShimmerCardSkeleton(),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return Center(
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Couldn\'t load this job',
                        message:
                            error is ApiException ? error.message : '$error',
                      ),
                    );
                  }
                  final job = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ResponsiveCenter(
                      child: _JobDetailBody(job: job, matchFuture: _matchFuture),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  final Map<String, dynamic> job;
  final Future<Map<String, dynamic>>? matchFuture;

  const _JobDetailBody({required this.job, required this.matchFuture});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final muted = Theme.of(context).hintColor;
    final skills = (job['requiredSkills'] as List?)?.cast<String>() ?? [];
    final applyLink = job['applyLink'] as String?;

    final company = job['company'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EntranceFade(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.glow(AppColors.primaryDark, opacity: 0.25),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyBadge(company: company),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title'] as String? ?? 'Untitled role',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(company,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _HeaderMeta(
                              icon: Icons.location_on_outlined,
                              label: job['location'] as String? ?? ''),
                          if (job['jobType'] != null)
                            _HeaderMeta(
                                icon: Icons.work_outline_rounded,
                                label: job['jobType'] as String),
                          if (job['experienceLevel'] != null)
                            _HeaderMeta(
                                icon: Icons.trending_up_rounded,
                                label: job['experienceLevel'] as String),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        EntranceFade(
          delay: const Duration(milliseconds: 100),
          child: Text('Match Score', style: AppTextStyles.heading2(textColor)),
        ),
        const SizedBox(height: 12),
        if (matchFuture != null)
          EntranceFade(
            delay: const Duration(milliseconds: 140),
            child: FutureBuilder<Map<String, dynamic>>(
              future: matchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppShimmer(
                      child: ShimmerBlock(height: 60, borderRadius: 12));
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  if (error is ApiException &&
                      isFeaturePending(error.statusCode)) {
                    return const AiComingSoon(feature: 'Job match scoring');
                  }
                  return Text(
                      error is ApiException ? error.message : 'Unavailable',
                      style: AppTextStyles.bodyMedium(muted));
                }
                final score = (snapshot.data?['matchScore'] as num?)?.toInt();
                if (score == null) {
                  return Text('Match data unavailable',
                      style: AppTextStyles.bodyMedium(muted));
                }
                final color = score >= 75
                    ? AppColors.successDark
                    : score >= 50
                        ? AppColors.warningDark
                        : AppColors.errorDark;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(value * 100).round()}%',
                          style: AppTextStyles.heading2(color)),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        EntranceFade(
          delay: const Duration(milliseconds: 180),
          child: Text('Description', style: AppTextStyles.heading2(textColor)),
        ),
        const SizedBox(height: 10),
        EntranceFade(
          delay: const Duration(milliseconds: 200),
          child: Text(job['description'] as String? ?? 'No description provided.',
              style: AppTextStyles.bodyMedium(textColor).copyWith(height: 1.5)),
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 24),
          EntranceFade(
            delay: const Duration(milliseconds: 240),
            child:
                Text('Required Skills', style: AppTextStyles.heading2(textColor)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < skills.length; i++)
                _AnimatedSkillChip(label: skills[i], index: i),
            ],
          ),
        ],
        const SizedBox(height: 32),
        if (applyLink != null && applyLink.isNotEmpty)
          EntranceFade(
            delay: const Duration(milliseconds: 300),
            child: CustomButton(
              label: 'Apply Now',
              icon: Icons.open_in_new_rounded,
              onPressed: () async {
                final uri = Uri.tryParse(applyLink);
                if (uri == null) return;
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  FeedbackManager.error(
                      context, 'Couldn\'t open the apply link');
                }
              },
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// No company logo URL exists in the `jobs` schema — this generates a
/// consistent-looking badge from the company's initial instead of leaving
/// an empty slot or a generic placeholder icon.
class _CompanyBadge extends StatelessWidget {
  final String company;
  const _CompanyBadge({required this.company});

  @override
  Widget build(BuildContext context) {
    final initial = company.trim().isEmpty ? '?' : company.trim()[0].toUpperCase();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
    );
  }
}

class _AnimatedSkillChip extends StatelessWidget {
  final String label;
  final int index;
  const _AnimatedSkillChip({required this.label, required this.index});

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

class _HeaderMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
