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
/// move faster than descriptions").
///
/// Sizes itself off BOTH the available width and height (via LayoutBuilder)
/// rather than width alone, and scrolls as a fallback — short/wide viewports
/// (landscape phones, some tablets) would otherwise overflow vertically.
class OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData data;
  final double pageDelta;

  const OnboardingSlide({super.key, required this.data, this.pageDelta = 0});

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
                  offset: Offset(pageDelta * 60, 0),
                  child: Opacity(
                    opacity: (1 - pageDelta.abs()).clamp(0.0, 1.0),
                    child: Container(
                      width: visualSize,
                      height: visualSize,
                      decoration: BoxDecoration(
                          gradient: data.gradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(data.icon,
                          size: visualSize * 0.4, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                    height: (constraints.maxHeight * 0.06).clamp(16.0, 48.0)),
                Transform.translate(
                  offset: Offset(pageDelta * 18, 0),
                  child: Text(
                    data.title,
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
                  offset: Offset(pageDelta * 10, 0),
                  child: Text(
                    data.description,
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
