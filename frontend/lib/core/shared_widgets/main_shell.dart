import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/config/theme.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.grid_view_rounded, 'Dashboard'),
  _NavItem(Icons.description_rounded, 'Resume'),
  _NavItem(Icons.alt_route_rounded, 'Roadmap'),
  _NavItem(Icons.psychology_rounded, 'AI Workspace'),
  _NavItem(Icons.work_rounded, 'Jobs'),
];

/// Root shell for the 5 bottom-nav tabs (Dashboard/Resume/Roadmap/AI
/// Workspace/Jobs). Each tab keeps its own navigation stack via go_router's
/// [StatefulShellRoute.indexedStack] — [navigationShell] is provided by
/// that route and swaps between branches without losing their state.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Floating, blurred bottom nav bar per docs/frontend_design_spec.md
/// section 4.A — active icon scales 1.2x with a glowing gradient indicator
/// line beneath it; inactive items are muted.
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                    .withOpacity(0.82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final selected = index == currentIndex;
                  return Expanded(
                    child: _NavBarButton(
                      icon: item.icon,
                      selected: selected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarButton(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final muted = Theme.of(context).hintColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(icon, color: selected ? primary : muted, size: 24),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
