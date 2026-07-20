import 'package:flutter/material.dart';

/// Breakpoints + helpers so screens adapt across small phones, large
/// phones, and tablets instead of just stretching edge-to-edge.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 360; // small phones
  static const double medium = 600; // large phones / small foldables
  static const double expanded = 905; // tablets
}

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.expanded) return ScreenSize.expanded;
  if (width >= AppBreakpoints.medium) return ScreenSize.medium;
  return ScreenSize.compact;
}

/// Clamps a value proportional to screen width between [min] and [max] —
/// used for visuals (icons, illustrations) that should shrink on small
/// phones and stop growing past a sensible cap on tablets.
double responsiveSize(BuildContext context,
    {required double fraction, required double min, required double max}) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * fraction).clamp(min, max);
}

/// Centers content and caps its width on tablets/large screens so forms and
/// reading-width text don't stretch uncomfortably wide, while staying full
/// width on phones.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 480});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
