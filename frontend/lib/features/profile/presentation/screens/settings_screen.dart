import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/constants/hero_tags.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/providers/theme_mode_provider.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _authService = AuthService();
  bool _pushEnabled = true;
  bool _emailEnabled = true;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content:
            const Text('You\'ll need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.errorDark)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(context, 'Couldn\'t log out. Please try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseStatus.isAvailable ? _authService.currentUser : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntranceFade(
                  child: user != null
                      ? _ProfileHero(user: user)
                      : const SizedBox(height: 12),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const EntranceFade(
                        delay: Duration(milliseconds: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Appearance'),
                            _SettingsGroup(children: [_ThemeModeSelector()]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      EntranceFade(
                        delay: const Duration(milliseconds: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Notifications'),
                            _SettingsGroup(children: [
                              _SwitchTile(
                                icon: Icons.notifications_active_outlined,
                                gradient: AppColors.primaryGradient,
                                title: 'Push notifications',
                                subtitle:
                                    'Job matches, roadmap and analysis updates',
                                value: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _pushEnabled = v),
                              ),
                              const _Divider(),
                              _SwitchTile(
                                icon: Icons.mail_outline_rounded,
                                gradient: AppColors.successGradient,
                                title: 'Email notifications',
                                subtitle:
                                    'Weekly digest and important account emails',
                                value: _emailEnabled,
                                onChanged: (v) =>
                                    setState(() => _emailEnabled = v),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      EntranceFade(
                        delay: const Duration(milliseconds: 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Account'),
                            _SettingsGroup(children: [
                              _NavTile(
                                icon: Icons.person_outline_rounded,
                                gradient: AppColors.primaryGradient,
                                title: 'Edit profile',
                                onTap: () =>
                                    context.push(AppRoutes.profileSetup),
                              ),
                              const _Divider(),
                              _NavTile(
                                icon: Icons.workspace_premium_outlined,
                                gradient: AppColors.premiumGradient,
                                title: 'Manage subscription',
                                onTap: () =>
                                    context.push(AppRoutes.premiumSubscription),
                              ),
                              const _Divider(),
                              _NavTile(
                                icon: Icons.bar_chart_rounded,
                                gradient: AppColors.successGradient,
                                title: 'Progress analytics',
                                onTap: () =>
                                    context.push(AppRoutes.progressAnalytics),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      EntranceFade(
                        delay: const Duration(milliseconds: 210),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('About'),
                            _SettingsGroup(children: [
                              _NavTile(
                                icon: Icons.privacy_tip_outlined,
                                gradient: AppColors.primaryGradient,
                                title: 'Privacy policy',
                                onTap: () {},
                              ),
                              const _Divider(),
                              _NavTile(
                                icon: Icons.description_outlined,
                                gradient: AppColors.primaryGradient,
                                title: 'Terms of service',
                                onTap: () {},
                              ),
                              const _Divider(),
                              const _InfoTile(
                                  title: 'App version', value: '1.0.0'),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      EntranceFade(
                        delay: const Duration(milliseconds: 260),
                        child: _SettingsGroup(children: [
                          _NavTile(
                            icon: Icons.logout_rounded,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.errorDark,
                                AppColors.warningDark
                              ],
                            ),
                            title: 'Log out',
                            textColor: AppColors.errorDark,
                            onTap: _confirmLogout,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large profile hero replacing the old flat account-info row — bigger
/// animated avatar, gradient backdrop, quick "Edit" action, matching the
/// hero-header treatment used on Home Dashboard for visual consistency
/// across the app's main tabs.
class _ProfileHero extends StatelessWidget {
  final User user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'Your account';
    final email = user.email ?? '';
    final initials =
        name == 'Your account' ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.profileSetup),
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            // Same Hero tag as the Home Dashboard's avatar — arriving here
            // via that avatar morphs smoothly into this larger one instead
            // of a plain cut between screens.
            child: Hero(
              tag: HeroTags.userAvatar,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryDark,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(email,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label.toUpperCase(),
          style: AppTextStyles.caption(Theme.of(context).hintColor)
              .copyWith(letterSpacing: 0.6)),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 64, color: Theme.of(context).dividerColor);
}

/// Small gradient-badge icon shared by nav/switch tiles so every settings
/// row reads as part of the same colored-icon language used on the
/// Dashboard and Notifications screens, instead of flat single-tone icons.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  const _IconBadge({required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _NavTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon: icon, gradient: gradient),
      title: Text(title,
          style: TextStyle(
              color: textColor ?? Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w500)),
      trailing:
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const _IconBadge(
          icon: Icons.info_outline_rounded,
          gradient: AppColors.primaryGradient),
      title: Text(title,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w500)),
      trailing: Text(value,
          style: AppTextStyles.bodyMedium(Theme.of(context).hintColor)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: _IconBadge(icon: icon, gradient: gradient),
      title: Text(title,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: AppTextStyles.caption(Theme.of(context).hintColor)),
      value: value,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

/// Watches [themeModeProvider] itself (instead of receiving it from the
/// parent) so a theme toggle only rebuilds these three buttons — not the
/// whole Settings page (profile hero, account tiles, etc.) above it.
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  static const _options = [
    (mode: ThemeMode.light, icon: Icons.light_mode_rounded, label: 'Light'),
    (mode: ThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
    (
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_rounded,
      label: 'Auto'
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final muted = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: _options.map((option) {
          final selected = current == option.mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (selected) return;
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).state = option.mode;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 170),
                        child: Icon(option.icon,
                            key: ValueKey(selected),
                            color: selected ? Colors.white : muted,
                            size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : muted),
                      child: Text(option.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
