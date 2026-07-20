import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/config/theme.dart';

/// Frosted-glass panel — blurred translucent surface with a hairline
/// gradient border. Used sparingly (hero cards, auth forms, floating bars)
/// rather than for every card, since overuse of blur both looks noisy and
/// costs more to render than a flat surface.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;

  /// Overrides the surrounding [Theme]'s brightness for glass tinting —
  /// use on screens that render a fixed dark ambient backdrop (splash/auth)
  /// regardless of the user's light/dark theme preference.
  final Brightness? brightness;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.borderRadius = AppRadius.large,
    this.blurSigma = 20,
    this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = this.brightness ?? Theme.of(context).brightness;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassSurface(brightness),
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                Border.all(color: AppColors.glassBorder(brightness), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
