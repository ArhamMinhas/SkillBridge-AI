import 'package:flutter/material.dart';

/// Text with a soft light sweep animating across it — a subtle "shine"
/// pass rather than a full color-cycling gradient, so it reads as a
/// premium accent instead of a distracting effect.
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextOverflow? overflow;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.overflow,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? Colors.white;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Sweeps a highlight band from -1.5 to 1.5 across the text's
          // shader space so it enters and fully exits each cycle.
          final sweep = _controller.value * 3.0 - 1.5;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, Colors.white, baseColor],
              stops: [
                (sweep - 0.3).clamp(0.0, 1.0),
                sweep.clamp(0.0, 1.0),
                (sweep + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds),
            child: child,
          );
        },
        child:
            Text(widget.text, style: widget.style, overflow: widget.overflow),
      ),
    );
  }
}
