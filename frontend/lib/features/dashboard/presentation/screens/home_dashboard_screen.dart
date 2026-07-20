import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class _DashboardStats {
  final int profileCompletionScore;
  final int newJobMatches;
  final int? latestAtsScore;
  final int? roadmapProgressPercent;

  const _DashboardStats({
    required this.profileCompletionScore,
    required this.newJobMatches,
    this.latestAtsScore,
    this.roadmapProgressPercent,
  });

  factory _DashboardStats.fromJson(Map<String, dynamic> json) =>
      _DashboardStats(
        profileCompletionScore: json['profileCompletionScore'] ?? 0,
        newJobMatches: json['newJobMatches'] ?? 0,
        latestAtsScore: json['latestAtsScore'],
        roadmapProgressPercent: json['roadmapProgressPercent'],
      );
}

class _WorkspaceModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;

  const _WorkspaceModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
  });
}

const _modules = [
  _WorkspaceModule(
    title: 'Resume Analyzer',
    subtitle: 'Get an ATS score in seconds',
    icon: Icons.description_rounded,
    gradient: AppColors.primaryGradient,
    route: AppRoutes.resumeUpload,
  ),
  _WorkspaceModule(
    title: 'Career Roadmap',
    subtitle: 'Your AI-generated growth plan',
    icon: Icons.alt_route_rounded,
    gradient: AppColors.successGradient,
    route: AppRoutes.careerRoadmap,
  ),
  _WorkspaceModule(
    title: 'Mock Interview',
    subtitle: 'Practice with AI feedback',
    icon: Icons.mic_rounded,
    gradient: AppColors.premiumGradient,
    route: AppRoutes.aiMockInterview,
  ),
  _WorkspaceModule(
    title: 'Skill Gap Report',
    subtitle: 'See what to learn next',
    icon: Icons.insights_rounded,
    gradient: AppColors.primaryGradient,
    route: AppRoutes.skillGapReport,
  ),
];

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _authService = AuthService();
  Future<_DashboardStats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<_DashboardStats> _loadStats() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiPaths.dashboardStats,
    );
    return _DashboardStats.fromJson(response.data!);
  }

  Future<void> _refresh() async {
    setState(() => _statsFuture = _loadStats());
    await _statsFuture;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'there';
    final initials = name == 'there'
        ? 'S'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((s) => s[0])
            .join()
            .toUpperCase();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: EntranceFade(
                    child: _DashboardHeader(
                      greeting: _greeting(),
                      name: name,
                      initials: initials,
                      onBell: () => context.push(AppRoutes.notifications),
                      onAvatar: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: FutureBuilder<_DashboardStats>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _StatsShimmer();
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: EmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Couldn\'t load your stats',
                            message: snapshot.error is ApiException
                                ? (snapshot.error as ApiException).message
                                : 'Something went wrong. Please try again',
                            actionLabel: 'Retry',
                            onAction: _refresh,
                          ),
                        );
                      }
                      final stats = snapshot.data!;
                      return EntranceFade(
                        delay: const Duration(milliseconds: 100),
                        child: _StatsGrid(stats: stats),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: EntranceFade(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                      child: Text('Your AI workspace',
                          style: AppTextStyles.heading2(
                              Theme.of(context).textTheme.bodyLarge!.color!)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 620 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _modules.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: columns == 1 ? 3.4 : 2.6,
                          ),
                          itemBuilder: (context, index) {
                            final module = _modules[index];
                            return EntranceFade(
                              delay: Duration(milliseconds: 250 + index * 60),
                              child: _ModuleCard(
                                module: module,
                                onTap: () => context.push(module.route),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String initials;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  const _DashboardHeader({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.onBell,
    required this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onBell,
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAvatar,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_rounded,
                label: 'Profile',
                value: '${stats.profileCompletionScore}%',
                gradient: AppColors.primaryGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.work_rounded,
                label: 'Job matches',
                value: '${stats.newJobMatches}',
                gradient: AppColors.successGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.speed_rounded,
                label: 'ATS score',
                value: stats.latestAtsScore != null
                    ? '${stats.latestAtsScore}'
                    : '—',
                gradient: AppColors.premiumGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTextStyles.heading1(
                  Theme.of(context).textTheme.bodyLarge!.color!)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(Theme.of(context).hintColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppShimmer(
          child: Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                  child: const ShimmerBlock(
                      height: 108, borderRadius: AppRadius.card),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _WorkspaceModule module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: module.gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(module.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(module.title,
                      style: AppTextStyles.bodyLarge(
                          Theme.of(context).textTheme.bodyLarge!.color!)),
                  const SizedBox(height: 2),
                  Text(
                    module.subtitle,
                    style: AppTextStyles.caption(Theme.of(context).hintColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}
