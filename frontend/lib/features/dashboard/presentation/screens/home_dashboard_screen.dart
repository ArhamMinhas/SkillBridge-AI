import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/hero_tags.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/shared_widgets/animated_tap_scale.dart';
import '../../../../core/shared_widgets/aurora_header_background.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';
import '../../../../core/shared_widgets/shimmer_text.dart';

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
  final _scrollController = ScrollController();
  // Drives the header's subtle scroll-collapse (greeting/avatar scale,
  // aurora fade) via ValueListenableBuilder inside _DashboardHeader, so
  // only that small subtree rebuilds per scroll tick — not the whole
  // screen. Plain double, not an AnimationController: this tracks the
  // scroll position directly rather than playing a timed animation.
  final _collapseNotifier = ValueNotifier<double>(0.0);
  Future<_DashboardStats>? _statsFuture;

  static const _collapseDistance = 80.0;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    _collapseNotifier.value =
        (_scrollController.offset / _collapseDistance).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _collapseNotifier.dispose();
    super.dispose();
  }

  Future<_DashboardStats> _loadStats() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiPaths.dashboardStats,
    );
    return _DashboardStats.fromJson(response.data!);
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _loadStats();
    });
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
            controller: _scrollController,
            slivers: [
              // Header and stat cards are two independent, sequential
              // sliver children — no Stack/Positioned overlap between them.
              // A prior version tried to make the cards "float" over the
              // header's bottom edge using a manually-guessed negative
              // offset; that offset was wrong relative to the header's real
              // (content-dependent) height and ended up painting the cards
              // over the greeting text instead of just peeking over the
              // edge. Plain sequential layout can't have that class of bug:
              // each child's position is derived from actual sizes, never
              // guessed.
              // _DashboardHeader drives its own staggered brand/greeting/
              // name/avatar entrance internally — no outer EntranceFade
              // here, which would just double-animate the same reveal.
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: _DashboardHeader(
                    greeting: _greeting(),
                    name: name,
                    initials: initials,
                    collapse: _collapseNotifier,
                    onBell: () => context.push(AppRoutes.notifications),
                    onAvatar: () => context.push(AppRoutes.settings),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: FutureBuilder<_DashboardStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _StatsShimmer();
                        }
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              boxShadow:
                                  AppShadows.soft(Theme.of(context).brightness),
                            ),
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
                        // _StatCard drives its own staggered spring
                        // entrance per-card — no outer EntranceFade here.
                        return _StatsGrid(stats: stats);
                      },
                    ),
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

class _DashboardHeader extends StatefulWidget {
  final String greeting;
  final String name;
  final String initials;
  final ValueListenable<double> collapse;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  const _DashboardHeader({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.collapse,
    required this.onBell,
    required this.onAvatar,
  });

  @override
  State<_DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<_DashboardHeader>
    with TickerProviderStateMixin {
  // One-shot staggered entrance: brand mark, then greeting, then name,
  // then avatar — reads as a deliberate reveal instead of everything
  // popping in at once. 480ms sits inside the 400-500ms "page entrance"
  // band; every Interval below is a fraction of this total, so they all
  // scale together if this changes.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  // Loops for as long as the dashboard is visible: a soft breathing glow
  // behind the avatar, echoing the splash screen's brand motion language.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  // Continuous gentle vertical bob on the avatar — small amplitude, never
  // pauses, so the header always reads as "alive" rather than static.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  late final Animation<double> _brandOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn));
  late final Animation<double> _greetingSlide = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic));
  late final Animation<double> _nameSlide = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic));
  late final Animation<double> _avatarScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _entrance.dispose();
    _glow.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraHeaderBackground(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      colors: const [AppColors.primaryDark, AppColors.secondaryDark],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _brandOpacity,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_graph_rounded,
                        color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 6),
                  Text('SkillBridge AI',
                      style: AppTextStyles.overline(
                          Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<double>(
              valueListenable: widget.collapse,
              builder: (context, collapse, child) {
                // Transform-only (scale), never a layout/padding change —
                // stays compositor-cheap on every scroll tick instead of
                // forcing a relayout of the sliver above it.
                return Transform.scale(
                  scale: 1 - (collapse * 0.08),
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(0, 0.5), end: Offset.zero)
                              .animate(_greetingSlide),
                          child: FadeTransition(
                            opacity: _greetingSlide,
                            child: Text(widget.greeting,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(0, 0.5), end: Offset.zero)
                              .animate(_nameSlide),
                          child: FadeTransition(
                            opacity: _nameSlide,
                            child: ShimmerText(
                              text: widget.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleTransition(
                    scale: _avatarScale,
                    child: IconButton(
                      onPressed: widget.onBell,
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ScaleTransition(
                    scale: _avatarScale,
                    child: _DashboardAvatar(
                      initials: widget.initials,
                      glow: _glow,
                      float: _float,
                      onTap: widget.onAvatar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashboard's avatar: Hero-linked to Settings' larger profile avatar
/// (tapping morphs into it rather than cutting), gradient border ring,
/// breathing glow, gentle continuous float, an online indicator, and
/// press-scale feedback via [AnimatedTapScale].
class _DashboardAvatar extends StatelessWidget {
  final String initials;
  final Animation<double> glow;
  final Animation<double> float;
  final VoidCallback onTap;

  const _DashboardAvatar({
    required this.initials,
    required this.glow,
    required this.float,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedBuilder(
        animation: Listenable.merge([glow, float]),
        builder: (context, child) {
          final bob = (float.value - 0.5) * 4;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
                  Colors.white,
                  Colors.white24,
                  Colors.white,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.18 + glow.value * 0.14),
                    blurRadius: 14 + glow.value * 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Hero(
          tag: HeroTags.userAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.successDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDark, width: 2),
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

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            index: 0,
            icon: Icons.person_rounded,
            label: 'Profile',
            numericValue: stats.profileCompletionScore,
            suffix: '%',
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            index: 1,
            icon: Icons.work_rounded,
            label: 'Job matches',
            numericValue: stats.newJobMatches,
            suffix: '',
            gradient: AppColors.successGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            index: 2,
            icon: Icons.speed_rounded,
            label: 'ATS score',
            numericValue: stats.latestAtsScore,
            suffix: '',
            gradient: AppColors.premiumGradient,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int? numericValue;
  final String suffix;
  final Gradient gradient;

  const _StatCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.numericValue,
    required this.suffix,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // A plain, theme-respecting card — not GlassCard. Glass tinting only
    // reads correctly over a colorful/varied backdrop (which is why it's
    // still used for the header-overlap treatment on Settings); once these
    // cards moved to sit on the flat scaffold background, the old
    // forced-white text became invisible against a light theme's white
    // background. A normal themed surface has no such failure mode.
    final brightness = Theme.of(context).brightness;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return TweenAnimationBuilder<double>(
      // Staggered spring entrance: each card starts a little later than
      // the one before it (index * 90ms), landing with a slight overshoot
      // via easeOutBack rather than just cross-fading in.
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 35),
      curve: Curves.easeOutBack,
      builder: (context, entrance, child) {
        return Opacity(
          opacity: entrance.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - entrance.clamp(0.0, 1.0)) * 16),
            child: Transform.scale(scale: entrance, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: AppShadows.soft(brightness),
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
            numericValue == null
                ? Text('—', style: AppTextStyles.heading1(textColor))
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: numericValue!.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, count, _) => Text(
                        '${count.round()}$suffix',
                        style: AppTextStyles.heading1(textColor)),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption(Theme.of(context).hintColor),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
              child:
                  const ShimmerBlock(height: 108, borderRadius: AppRadius.card),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _WorkspaceModule module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  // MouseRegion.onEnter/onExit simply never fire on touch-only devices, so
  // this is a no-op cost on mobile and a real hover affordance on web/
  // desktop — no platform branching needed.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedTapScale(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: _hovered
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    (isDark ? 0.25 : 0.05) + (_hovered ? 0.05 : 0)),
                blurRadius: _hovered ? 20 : 14,
                offset: Offset(0, _hovered ? 6 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.module.gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.module.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.module.title,
                        style: AppTextStyles.bodyLarge(
                            Theme.of(context).textTheme.bodyLarge!.color!)),
                    const SizedBox(height: 2),
                    Text(
                      widget.module.subtitle,
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
      ),
    );
  }
}
