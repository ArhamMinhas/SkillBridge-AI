import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/shared_widgets/empty_state.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/shimmer_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!FirebaseStatus.isAvailable) {
      return const EmptyState(
        icon: Icons.notifications_off_rounded,
        title: 'Notifications unavailable',
        message:
            'Firebase isn\'t configured yet — connect a project to see notifications',
      );
    }

    final user = _authService.currentUser;
    if (user == null) {
      return const EmptyState(
        icon: Icons.notifications_off_rounded,
        title: 'Not signed in',
        message: 'Log in to see your notifications',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationService.notificationHistory(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 6,
            itemBuilder: (context, index) => const ShimmerCardSkeleton(),
          );
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Couldn\'t load notifications',
            message: '${snapshot.error}',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'You\'re all caught up',
            message:
                'New job matches, roadmap updates, and analysis results will show up here',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return EntranceFade(
              delay: Duration(milliseconds: index * 40),
              child: Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.errorDark.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  await _notificationService.markAsRead(doc.id);
                  return false;
                },
                child: _NotificationTile(
                  title: data['title'] ?? 'Notification',
                  body: data['body'] ?? '',
                  category: data['category'] ?? 'general',
                  isRead: data['isRead'] ?? false,
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                  onTap: () {
                    if (data['isRead'] != true) {
                      _notificationService.markAsRead(doc.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

const _categoryIcons = {
  'job': Icons.work_rounded,
  'roadmap': Icons.alt_route_rounded,
  'resume': Icons.description_rounded,
  'interview': Icons.mic_rounded,
  'payment': Icons.payment_rounded,
  'system': Icons.info_rounded,
};

const _categoryGradients = {
  'job': AppColors.successGradient,
  'roadmap': AppColors.primaryGradient,
  'resume': AppColors.primaryGradient,
  'interview': AppColors.premiumGradient,
  'payment': AppColors.premiumGradient,
  'system': AppColors.primaryGradient,
};

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String category;
  final bool isRead;
  final DateTime? createdAt;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final gradient = _categoryGradients[category] ?? AppColors.primaryGradient;
    final icon = _categoryIcons[category] ?? Icons.notifications_rounded;

    return Material(
      color: isRead
          ? Theme.of(context).cardColor
          : Theme.of(context).primaryColor.withOpacity(isDark ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(gradient: gradient, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLarge(textColor)
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: AppTextStyles.bodyMedium(
                            Theme.of(context).hintColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_timeAgo(createdAt),
                        style:
                            AppTextStyles.caption(Theme.of(context).hintColor)),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
