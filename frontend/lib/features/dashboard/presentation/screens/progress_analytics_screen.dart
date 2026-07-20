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
                if (data.isEmpty) {
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
                    EntranceFade(
                      child: _MetricsGrid(data: data),
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

class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricsGrid({required this.data});

  String _labelFor(String key) {
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        data.entries.where((e) => e.value is! Map && e.value is! List).toList();
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${entry.value}',
                  style: AppTextStyles.heading1(
                      Theme.of(context).textTheme.bodyLarge!.color!)),
              const SizedBox(height: 4),
              Text(_labelFor(entry.key),
                  style: AppTextStyles.caption(Theme.of(context).hintColor)),
            ],
          ),
        );
      },
    );
  }
}
