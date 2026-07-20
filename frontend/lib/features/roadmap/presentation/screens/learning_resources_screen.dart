import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/shared_widgets/ai_coming_soon.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

const _typeIcons = {
  'course': Icons.school_rounded,
  'video': Icons.play_circle_rounded,
  'article': Icons.article_rounded,
  'book': Icons.menu_book_rounded,
};

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await ApiClient.instance
        .get<dynamic>(ApiPaths.learningResourcesRecommendation);
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['resources'] is List) {
      return (data['resources'] as List).cast<Map<String, dynamic>>();
    }
    return [];
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
      appBar: AppBar(title: const Text('Learning Resources')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ResponsiveCenter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                        const ShimmerCardSkeleton(),
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
                            feature: 'Learning resource recommendations',
                            onRetry: _refresh),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Text(
                            error is ApiException
                                ? error.message
                                : 'Something went wrong',
                            style: AppTextStyles.bodyMedium(
                                Theme.of(context).hintColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final resources = snapshot.data ?? [];
                if (resources.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AiComingSoon(
                          feature: 'Learning resource recommendations',
                          onRetry: _refresh),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: resources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = resources[index];
                    return EntranceFade(
                      delay: Duration(milliseconds: index * 50),
                      child: _ResourceCard(resource: r),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Map<String, dynamic> resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final title = resource['title'] as String? ?? 'Resource';
    final description = resource['description'] as String? ?? '';
    final type = (resource['type'] as String? ?? 'article').toLowerCase();
    final url = resource['url'] as String?;
    final icon = _typeIcons[type] ?? Icons.link_rounded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: url == null
            ? null
            : () async {
                final uri = Uri.tryParse(url);
                if (uri == null) return;
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  FeedbackManager.error(context, 'Couldn\'t open this link');
                }
              },
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLarge(
                            Theme.of(context).textTheme.bodyLarge!.color!)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(description,
                          style: AppTextStyles.caption(
                              Theme.of(context).hintColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (url != null)
                Icon(Icons.open_in_new_rounded,
                    color: Theme.of(context).hintColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
