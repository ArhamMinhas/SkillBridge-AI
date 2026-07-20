import 'package:flutter/material.dart';

/// A colorful "G" mark evoking Google's brand palette, for the "Continue
/// with Google" button — built from a sweep gradient rather than a bundled
/// logo asset, since no external image/SVG assets are available here.
class GoogleGMark extends StatelessWidget {
  final double size;
  const GoogleGMark({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const SweepGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(bounds),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
