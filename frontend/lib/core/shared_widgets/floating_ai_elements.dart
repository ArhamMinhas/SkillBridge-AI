import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/config/theme.dart';

/// Small glowing AI-themed icon chips slowly orbiting [child]. This project
/// has no illustration/3D-asset library, so this is the code-only stand-in
/// for the redesign directive's "hero illustration / floating AI elements"
/// ask on Login/Register — same "premium, alive, AI-powered" first
/// impression, built from existing primitives (icons, gradients, a single
/// looping animation) instead of a new asset dependency.
class FloatingAiElements extends StatefulWidget {
  final Widget child;
  final double radius;

  const FloatingAiElements({super.key, required this.child, this.radius = 58});

  @override
  State<FloatingAiElements> createState() => _FloatingAiElementsState();
}

class _FloatingAiElementsState extends State<FloatingAiElements>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  static const _icons = [
    Icons.auto_awesome_rounded,
    Icons.psychology_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = (widget.radius + 20) * 2;
    return SizedBox(
      width: box,
      height: box * 0.75,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            return Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                for (var i = 0; i < _icons.length; i++) _orbIcon(i, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _orbIcon(int index, double t) {
    // Coefficients on `t` are kept as whole numbers so every orbit/bob cycle
    // completes in exact sync with the controller's repeat — otherwise the
    // position would jump when the controller wraps from 2π back to 0.
    final phase = index * (2 * math.pi / _icons.length);
    final angle = t + phase;
    final bob = math.sin(2 * t + phase) * 6;
    final dx = math.cos(angle) * widget.radius;
    final dy = math.sin(angle) * widget.radius * 0.55 + bob;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.primaryDark, opacity: 0.35),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(_icons[index], color: Colors.white, size: 15),
      ),
    );
  }
}
