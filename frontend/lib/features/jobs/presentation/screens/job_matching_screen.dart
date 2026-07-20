import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class JobMatchingScreen extends StatefulWidget {
  const JobMatchingScreen({super.key});

  @override
  State<JobMatchingScreen> createState() => _JobMatchingScreenState();
}

class _JobMatchingScreenState extends State<JobMatchingScreen> {
  final _searchController = TextEditingController();
  String? _jobTypeFilter;
  late Future<List<Map<String, dynamic>>> _future;

  static const _jobTypes = ['full-time', 'part-time', 'internship', 'contract'];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await ApiClient.instance.get<List<dynamic>>(
      ApiPaths.jobs,
      query: {
        if (_searchController.text.trim().isNotEmpty)
          'skill': _searchController.text.trim(),
        if (_jobTypeFilter != null) 'jobType': _jobTypeFilter,
      },
    );
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Matches')),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _refresh(),
                      decoration: InputDecoration(
                        hintText: 'Search by skill (e.g. Flutter)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _refresh();
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _jobTypes.map((type) {
                          final selected = _jobTypeFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_labelFor(type)),
                              selected: selected,
                              onSelected: (_) {
                                setState(() =>
                                    _jobTypeFilter = selected ? null : type);
                                _refresh();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 5,
                          itemBuilder: (context, index) =>
                              const ShimmerCardSkeleton(),
                        );
                      }

                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: EmptyState(
                                icon: Icons.wifi_off_rounded,
                                title: 'Couldn\'t load jobs',
                                message: error is ApiException
                                    ? error.message
                                    : 'Something went wrong',
                                actionLabel: 'Retry',
                                onAction: _refresh,
                              ),
                            ),
                          ],
                        );
                      }

                      final jobs = snapshot.data ?? [];
                      if (jobs.isEmpty) {
                        return ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: EmptyState(
                                icon: Icons.work_off_rounded,
                                title: 'No jobs found',
                                message:
                                    'Try a different skill or clear your filters.',
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return EntranceFade(
                            delay: Duration(milliseconds: index * 40),
                            child: _JobCard(
                              job: job,
                              onTap: () => context.push(
                                  '${AppRoutes.jobDetail}?id=${job['id']}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String type) =>
      type.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final skills = (job['requiredSkills'] as List?)?.cast<String>() ?? [];

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job['title'] as String? ?? 'Untitled role',
                            style: AppTextStyles.bodyLarge(textColor)
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(job['company'] as String? ?? '',
                            style: AppTextStyles.bodyMedium(
                                Theme.of(context).hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                      icon: Icons.location_on_outlined,
                      label: job['location'] as String? ?? ''),
                  if (job['jobType'] != null)
                    _MetaChip(
                        icon: Icons.work_outline_rounded,
                        label: job['jobType'] as String),
                  if (job['experienceLevel'] != null)
                    _MetaChip(
                        icon: Icons.trending_up_rounded,
                        label: job['experienceLevel'] as String),
                ],
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills
                      .take(4)
                      .map((s) => Chip(
                            label:
                                Text(s, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).hintColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption(muted)),
      ],
    );
  }
}
