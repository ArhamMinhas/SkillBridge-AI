import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// SkillBridge AI's real logo mark (`assets/icon/app_icon_foreground.png` —
/// the same source art the launcher icon is generated from, with its outer
/// black canvas stripped to transparency). Wrapped in a [Hero] so it morphs
/// between Splash/Login/Register wherever it reappears.
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
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryDark.withOpacity(0.4),
              blurRadius: size * 0.45,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: Image.asset(
          'assets/icon/app_icon_foreground.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
