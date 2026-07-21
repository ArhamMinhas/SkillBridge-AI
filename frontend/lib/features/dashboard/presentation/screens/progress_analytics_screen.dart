import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  State<ProgressAnalyticsScreen> createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiPaths.progressAnalytics);
    return response.data ?? {};
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
      appBar: AppBar(title: const Text('Progress Analytics')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ResponsiveCenter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
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
                  if (error is ApiException &&
                      isFeaturePending(error.statusCode)) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        AiComingSoon(
                            feature: 'Progress predictions', onRetry: _refresh),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Couldn\'t load analytics',
                        message:
                            error is ApiException ? error.message : '$error',
                        actionLabel: 'Retry',
                        onAction: _refresh,
                      ),
                    ],
                  );
                }

                final data = snapshot.data ?? {};
                final entries = data.entries
                    .where((e) => e.value is num)
                    .toList(growable: false);
                if (entries.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      AiComingSoon(feature: 'Progress predictions'),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    EntranceFade(child: _ProgressBarChart(entries: entries)),
                    const SizedBox(height: 20),
                    EntranceFade(
                      delay: const Duration(milliseconds: 100),
                      child: _MetricsGrid(entries: entries),
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

const _kMetricIcons = <String, IconData>{
  'skill': Icons.psychology_rounded,
  'learning': Icons.school_rounded,
  'resume': Icons.description_rounded,
  'interview': Icons.record_voice_over_rounded,
  'career': Icons.route_rounded,
  'roadmap': Icons.route_rounded,
};

const _kMetricGradients = <Gradient>[
  AppColors.primaryGradient,
  AppColors.successGradient,
  AppColors.premiumGradient,
];

IconData _iconForMetric(String key) {
  final lower = key.toLowerCase();
  for (final entry in _kMetricIcons.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return Icons.trending_up_rounded;
}

String _labelFor(String key) {
  final spaced = key.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Animated bar chart giving an at-a-glance comparison across every numeric
/// progress dimension the backend returns (skill/learning/resume/interview/
/// career progress, per the redesign directive's "charts / graphs" ask) —
/// bars grow in from zero on first paint rather than appearing static.
class _ProgressBarChart extends StatelessWidget {
  final List<MapEntry<String, dynamic>> entries;
  const _ProgressBarChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).hintColor;
    final maxVal = entries.fold<double>(
        10, (max, e) => (e.value as num).toDouble() > max ? (e.value as num).toDouble() : max);

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return BarChart(
            BarChartData(
              maxY: maxVal * 1.25,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final label = _labelFor(entries[i].key).split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(label, style: AppTextStyles.caption(muted)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < entries.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: (entries[i].value as num).toDouble() * t,
                      gradient: _kMetricGradients[i % _kMetricGradients.length],
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<MapEntry<String, dynamic>> entries;
  const _MetricsGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _MetricCard(
          label: _labelFor(entry.key),
          value: (entry.value as num).toDouble(),
          icon: _iconForMetric(entry.key),
          gradient: _kMetricGradients[index % _kMetricGradients.length],
          index: index,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Gradient gradient;
  final int index;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 35),
      curve: Curves.easeOutBack,
      builder: (context, entrance, child) => Opacity(
        opacity: entrance.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - entrance.clamp(0.0, 1.0)) * 16),
          child: Transform.scale(scale: entrance, child: child),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft(Theme.of(context).brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, count, _) => Text(
                '${count.round()}${value <= 100 ? '%' : ''}',
                style: AppTextStyles.heading1(textColor),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption(Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
