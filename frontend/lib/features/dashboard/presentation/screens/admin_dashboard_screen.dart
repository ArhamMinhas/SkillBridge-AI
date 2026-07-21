import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_AdminData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminData> _load() async {
    final results = await Future.wait([
      ApiClient.instance.get<Map<String, dynamic>>(ApiPaths.adminAnalytics),
      ApiClient.instance.get<List<dynamic>>(ApiPaths.adminUsers),
    ]);
    final analytics = results[0].data as Map<String, dynamic>;
    final users = (results[1].data as List).cast<Map<String, dynamic>>();
    return _AdminData(analytics: analytics, users: users);
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
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ResponsiveCenter(
            child: FutureBuilder<_AdminData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      ShimmerCardSkeleton(),
                      ShimmerCardSkeleton(),
                      ShimmerCardSkeleton(),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final isForbidden =
                      error is ApiException && error.statusCode == 403;
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      EmptyState(
                        icon: isForbidden
                            ? Icons.lock_outline_rounded
                            : Icons.wifi_off_rounded,
                        title: isForbidden
                            ? 'Admins only'
                            : 'Couldn\'t load admin data',
                        message: error is ApiException
                            ? error.message
                            : 'Something went wrong',
                        actionLabel: isForbidden ? null : 'Retry',
                        onAction: isForbidden ? null : _refresh,
                      ),
                    ],
                  );
                }

                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    EntranceFade(
                      child: _StatsRow(analytics: data.analytics),
                    ),
                    const SizedBox(height: 28),
                    EntranceFade(
                      delay: const Duration(milliseconds: 100),
                      child: Text('Recent Users',
                          style: AppTextStyles.heading2(
                              Theme.of(context).textTheme.bodyLarge!.color!)),
                    ),
                    const SizedBox(height: 12),
                    ...data.users.take(20).toList().asMap().entries.map(
                          (entry) => EntranceFade(
                            delay: Duration(milliseconds: 150 + entry.key * 30),
                            child: _UserTile(user: entry.value),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminData {
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> users;
  const _AdminData({required this.analytics, required this.users});
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _StatsRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final totalUsers = analytics['totalUsers'] ?? 0;
    final premiumUsers = analytics['premiumUsers'] ?? 0;
    final totalJobs = analytics['totalJobs'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            label: 'Total Users',
            value: '$totalUsers',
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium_rounded,
            label: 'Premium',
            value: '$premiumUsers',
            gradient: AppColors.premiumGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.work_rounded,
            label: 'Jobs',
            value: '$totalJobs',
            gradient: AppColors.successGradient,
          ),
        ),
      ],
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
    final numericValue = int.tryParse(value);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(
                  (gradient as LinearGradient).colors.first,
                  opacity: 0.3),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          numericValue == null
              ? Text(value,
                  style: AppTextStyles.heading1(
                      Theme.of(context).textTheme.bodyLarge!.color!))
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: numericValue.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, count, _) => Text('${count.round()}',
                      style: AppTextStyles.heading1(
                          Theme.of(context).textTheme.bodyLarge!.color!)),
                ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption(Theme.of(context).hintColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final name = user['name'] as String? ?? 'Unnamed user';
    final email = user['email'] as String? ?? '';
    final isPremium = user['isPremium'] == true;
    final initials =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
            child: Text(initials,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyLarge(textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(email,
                    style: AppTextStyles.caption(Theme.of(context).hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('PRO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
