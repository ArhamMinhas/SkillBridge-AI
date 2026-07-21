import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact aurora-style shifting gradient — two soft color blobs drifting
/// slowly behind [child], clipped to the header's own shape. This is the
/// same "ambient blob" technique as [MeshGradientBackground] (full-screen,
/// used on auth screens) scaled down and contained for use inside a
/// bounded header rather than behind the whole app, so headers can have
/// the same "alive" motion language without needing a second, heavier
/// full-screen widget.
class AuroraHeaderBackground extends StatefulWidget {
  final Widget? child;
  final BorderRadius borderRadius;
  final List<Color> colors;

  const AuroraHeaderBackground({
    super.key,
    this.child,
    required this.borderRadius,
    required this.colors,
  });

  @override
  State<AuroraHeaderBackground> createState() => _AuroraHeaderBackgroundState();
}

class _AuroraHeaderBackgroundState extends State<AuroraHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No StackFit.expand: this header must size itself from its CONTENT
    // (the greeting/avatar column passed as `child`), not from an ancestor
    // — and nothing above provides a bounded height to expand into (the
    // old plain Container relied on Container's content-based sizing,
    // which Stack(fit: expand) does not do — it demands a finite size from
    // its parent instead, which crashes with "BoxConstraints forces an
    // infinite height" here). Stack's default (loose) sizing instead sizes
    // itself to its one un-positioned child (`child`, appended last) and
    // the Positioned.fill layers below then stretch to match that size.
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value * 2 * math.pi;
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment(
                            math.sin(t) * 0.8, math.cos(t * 0.7) * 0.6 - 0.4),
                        child: _blob(widget.colors.last, 180),
                      ),
                      Align(
                        alignment: Alignment(
                            math.cos(t * 0.6) * 0.7, math.sin(t * 0.8) * 0.7),
                        child: _blob(Colors.white, 140, opacity: 0.10),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, {double opacity = 0.28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}
