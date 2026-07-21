import 'package:flutter/material.dart';

class OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

/// Single onboarding slide with a parallax effect: the icon visual drifts
/// further than the title/description as [pageDelta] moves away from 0,
/// so the foreground visibly leads the text while swiping (per
/// docs/frontend_design_spec.md section 5 — "foreground vector elements
/// move faster than descriptions"). The icon also has a one-shot
/// entrance (scale + fade, played the first time this slide is built) and
/// a continuous gentle float + soft glow pulse so it never reads as a
/// static image.
///
/// Sizes itself off BOTH the available width and height (via LayoutBuilder)
/// rather than width alone, and scrolls as a fallback — short/wide viewports
/// (landscape phones, some tablets) would otherwise overflow vertically.
class OnboardingSlide extends StatefulWidget {
  final OnboardingSlideData data;
  final double pageDelta;

  const OnboardingSlide({super.key, required this.data, this.pageDelta = 0});

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  late final Animation<double> _entranceScale =
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack);
  late final Animation<double> _entranceOpacity =
      CurvedAnimation(parent: _entrance, curve: Curves.easeIn);

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final muted = Colors.white.withOpacity(0.65);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Bound the icon by both width and height so it never forces an
        // overflow, however narrow or short the viewport is.
        final visualSize = (constraints.maxWidth * 0.5)
            .clamp(120.0, 240.0)
            .clamp(0.0, constraints.maxHeight * 0.42);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(widget.pageDelta * 60, 0),
                  child: Opacity(
                    opacity: (1 - widget.pageDelta.abs()).clamp(0.0, 1.0),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entrance, _float]),
                      builder: (context, child) {
                        final bob = (_float.value - 0.5) * 10;
                        return Transform.translate(
                          offset: Offset(0, bob),
                          child: Transform.scale(
                            scale: _entranceScale.value,
                            child: Opacity(
                                opacity: _entranceOpacity.value, child: child),
                          ),
                        );
                      },
                      child: Container(
                        width: visualSize,
                        height: visualSize,
                        decoration: BoxDecoration(
                          gradient: widget.data.gradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.data.gradient as LinearGradient)
                                  .colors
                                  .first
                                  .withOpacity(0.35),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(widget.data.icon,
                            size: visualSize * 0.4, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    height: (constraints.maxHeight * 0.06).clamp(16.0, 48.0)),
                Transform.translate(
                  offset: Offset(widget.pageDelta * 18, 0),
                  child: Text(
                    widget.data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(widget.pageDelta * 10, 0),
                  child: Text(
                    widget.data.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
