import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/config/theme.dart';

/// Ambient full-bleed background for splash/auth screens: three softly
/// blurred brand-color blobs drifting independently over a dark base, plus
/// a field of slow-rising particles. Replaces the single-blob
/// [AnimatedGradientBackground] wherever a richer, more "alive" feel is
/// warranted (first-impression screens) — cheap enough to run continuously
/// since it's built from a handful of gradients and one CustomPainter.
class MeshGradientBackground extends StatefulWidget {
  final Widget? child;

  const MeshGradientBackground({super.key, this.child});

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blobController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late final AnimationController _particleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _blobController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Isolated in its own compositing layer: this repaints every
          // frame forever, and without a boundary that cost leaks into
          // whatever real content (forms, buttons) is stacked on top.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _blobController,
              builder: (context, _) {
                final t = _blobController.value * 2 * math.pi;
                return Stack(
                  children: [
                    _blob(
                      alignment: Alignment(
                          math.sin(t) * 0.6, math.cos(t * 0.8) * 0.5 - 0.6),
                      color: AppColors.primaryDark,
                      size: 340,
                      opacity: 0.22,
                    ),
                    _blob(
                      alignment: Alignment(
                          math.cos(t * 0.7) * 0.7, math.sin(t * 0.6) * 0.6),
                      color: AppColors.secondaryDark,
                      size: 300,
                      opacity: 0.18,
                    ),
                    _blob(
                      alignment: Alignment(math.sin(t * 0.5 + 2) * 0.5,
                          math.cos(t * 0.9) * 0.5 + 0.7),
                      color: AppColors.accentDark,
                      size: 260,
                      opacity: 0.14,
                    ),
                  ],
                );
              },
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(progress: _particleController.value),
                size: Size.infinite,
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  Widget _blob({
    required Alignment alignment,
    required Color color,
    required double size,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final double radius;
  final double speed;
  final double phase;

  const _Particle(this.x, this.startY, this.radius, this.speed, this.phase);
}

// Fixed pseudo-random layout (seeded) so particles don't jump between
// rebuilds — only [_ParticlePainter.progress] animates.
final List<_Particle> _particles = List.generate(18, (i) {
  final rnd = math.Random(i * 97);
  return _Particle(
    rnd.nextDouble(),
    rnd.nextDouble(),
    1.2 + rnd.nextDouble() * 1.8,
    0.4 + rnd.nextDouble() * 0.6,
    rnd.nextDouble() * 2 * math.pi,
  );
});

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (final p in _particles) {
      final y = (p.startY - progress * p.speed) % 1.0;
      final drift = math.sin(progress * 2 * math.pi + p.phase) * 8;
      final opacity = (math.sin(y * math.pi)).clamp(0.0, 1.0) * 0.35;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(p.x * size.width + drift, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
