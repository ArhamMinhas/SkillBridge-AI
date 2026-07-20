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
                      child: EntranceFade(
                        child:
                            _JobDetailBody(job: job, matchFuture: _matchFuture),
                      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job['title'] as String? ?? 'Untitled role',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(job['company'] as String? ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 15)),
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
        const SizedBox(height: 24),
        Text('Match Score', style: AppTextStyles.heading2(textColor)),
        const SizedBox(height: 12),
        if (matchFuture != null)
          FutureBuilder<Map<String, dynamic>>(
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
              return Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 10,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$score%', style: AppTextStyles.heading2(textColor)),
                ],
              );
            },
          ),
        const SizedBox(height: 24),
        Text('Description', style: AppTextStyles.heading2(textColor)),
        const SizedBox(height: 10),
        Text(job['description'] as String? ?? 'No description provided.',
            style: AppTextStyles.bodyMedium(textColor).copyWith(height: 1.5)),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Required Skills', style: AppTextStyles.heading2(textColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => Chip(
                      label: Text(s),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 32),
        if (applyLink != null && applyLink.isNotEmpty)
          CustomButton(
            label: 'Apply Now',
            icon: Icons.open_in_new_rounded,
            onPressed: () async {
              final uri = Uri.tryParse(applyLink);
              if (uri == null) return;
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (context.mounted) {
                FeedbackManager.error(context, 'Couldn\'t open the apply link');
              }
            },
          ),
        const SizedBox(height: 20),
      ],
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
