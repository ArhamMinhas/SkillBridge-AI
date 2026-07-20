import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null) _AccountCard(user: user),
                  const SizedBox(height: 24),
                  const _SectionLabel('Appearance'),
                  _SettingsGroup(children: [
                    _ThemeModeSelector(
                      current: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).state = mode,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Notifications'),
                  _SettingsGroup(children: [
                    _SwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push notifications',
                      subtitle: 'Job matches, roadmap and analysis updates',
                      value: _pushEnabled,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    const _Divider(),
                    _SwitchTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email notifications',
                      subtitle: 'Weekly digest and important account emails',
                      value: _emailEnabled,
                      onChanged: (v) => setState(() => _emailEnabled = v),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Account'),
                  _SettingsGroup(children: [
                    _NavTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit profile',
                      onTap: () => context.push(AppRoutes.profileSetup),
                    ),
                    const _Divider(),
                    _NavTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Manage subscription',
                      onTap: () => context.push(AppRoutes.premiumSubscription),
                    ),
                    const _Divider(),
                    _NavTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Progress analytics',
                      onTap: () => context.push(AppRoutes.progressAnalytics),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('About'),
                  _SettingsGroup(children: [
                    _NavTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy policy',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _NavTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of service',
                      onTap: () {},
                    ),
                    const _Divider(),
                    const _InfoTile(title: 'App version', value: '1.0.0'),
                  ]),
                  const SizedBox(height: 28),
                  _SettingsGroup(children: [
                    _NavTile(
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      iconColor: AppColors.errorDark,
                      textColor: AppColors.errorDark,
                      onTap: _confirmLogout,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final User user;

  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'Your account';
    final email = user.email ?? '';
    final initials =
        name == 'Your account' ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor);
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
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
      leading: Icon(Icons.info_outline_rounded,
          color: Theme.of(context).primaryColor),
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
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: AppTextStyles.caption(Theme.of(context).hintColor)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({required this.current, required this.onChanged});

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
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final muted = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: _options.map((option) {
          final selected = current == option.mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? primary.withOpacity(0.12) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          selected ? primary : Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Icon(option.icon,
                        color: selected ? primary : muted, size: 22),
                    const SizedBox(height: 6),
                    Text(option.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? primary : muted)),
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
