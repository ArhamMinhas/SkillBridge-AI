/// Central registry of static asset paths so screens never hardcode strings.
class AppAssets {
  AppAssets._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';

  static const String logo = '$_images/app_logo_highres.png';
  static const String logoForeground = '$_images/app_logo_foreground.png';
  static const String onboarding1 = '$_images/onboarding_resume.svg';
  static const String onboarding2 = '$_images/onboarding_roadmap.svg';
  static const String onboarding3 = '$_images/onboarding_premium.svg';
  static const String emptyState = '$_images/empty_state.svg';

  static const String aiLoading = '$_animations/ai_loading.json';
  static const String confetti = '$_animations/confetti.json';

  static const String iconGoogle = '$_icons/google.svg';
}
