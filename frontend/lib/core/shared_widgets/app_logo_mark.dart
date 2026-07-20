import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// SkillBridge AI's logo mark — a gradient glyph used until a real logo
/// asset is supplied. Wrapped in a [Hero] so it can morph between the
/// splash screen and wherever it reappears (e.g. a future loading screen).
class AppLogoMark extends StatelessWidget {
  final double size;

  const AppLogoMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app-logo-mark',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryDark.withOpacity(0.45),
              blurRadius: size * 0.5,
              spreadRadius: size * 0.04,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.auto_graph_rounded,
            color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
