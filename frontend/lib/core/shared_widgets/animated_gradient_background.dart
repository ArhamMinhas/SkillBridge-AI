import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// Full-bleed dark gradient with a slow-drifting soft glow blob. Used behind
/// splash/onboarding/auth screens so the whole app shares one ambient
/// background treatment instead of a flat color fill.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget? child;

  const AnimatedGradientBackground({super.key, this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.16 + (t * 0.1),
                  child: Container(
                    width: 320 + (t * 40),
                    height: 320 + (t * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondaryDark.withOpacity(0.9),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
