import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SkillBridge AI design tokens — see docs/frontend_design_spec.md section 2.
class AppColors {
  AppColors._();

  // Primary / secondary brand
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color secondaryLight = Color(0xFF7C3AED);
  static const Color secondaryDark = Color(0xFF8B5CF6);

  // Semantic
  static const Color successLight = Color(0xFF059669);
  static const Color successDark = Color(0xFF10B981);
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color errorLight = Color(0xFFE11D48);
  static const Color errorDark = Color(0xFFF43F5E);

  // Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text
  static const Color mutedLight = Color(0xFF64748B);
  static const Color mutedDark = Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, secondaryLight],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, errorDark],
  );
}

class AppRadius {
  AppRadius._();
  static const double card = 16;
  static const double button = 12;
  static const double input = 12;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display1(Color color) => GoogleFonts.outfit(
      fontSize: 32, fontWeight: FontWeight.w700, color: color);
  static TextStyle heading1(Color color) => GoogleFonts.outfit(
      fontSize: 24, fontWeight: FontWeight.w700, color: color);
  static TextStyle heading2(Color color) => GoogleFonts.outfit(
      fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w500, color: color);
  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle caption(Color color) => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, color: color);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        muted: AppColors.mutedLight,
        error: AppColors.errorLight,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        muted: AppColors.mutedDark,
        error: AppColors.errorDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color muted,
    required Color error,
  }) {
    final textColor =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textColor,
      ),
      cardColor: surface,
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: AppTextStyles.heading1(textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        // Extra top padding reserves room for the floating label so it
        // never crowds/overlaps the field above when it animates up.
        contentPadding:
            const EdgeInsets.only(top: 20, bottom: 16, left: 16, right: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: muted.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: muted.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle:
            TextStyle(color: primary, fontWeight: FontWeight.w600),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display1(textColor),
        headlineLarge: AppTextStyles.heading1(textColor),
        headlineMedium: AppTextStyles.heading2(textColor),
        bodyLarge: AppTextStyles.bodyLarge(textColor),
        bodyMedium: AppTextStyles.bodyMedium(textColor),
        bodySmall: AppTextStyles.caption(muted),
      ),
      dividerColor: muted.withOpacity(0.15),
      hintColor: muted,
      useMaterial3: true,
    );
  }
}
