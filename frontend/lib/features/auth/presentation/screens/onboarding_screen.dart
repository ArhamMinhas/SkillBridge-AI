import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    OnboardingSlideData(
      icon: Icons.description_rounded,
      title: 'AI Resume Optimization',
      description:
          'Get an instant ATS score, strengths, weaknesses, and\nmissing keywords powered by AI.',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingSlideData(
      icon: Icons.alt_route_rounded,
      title: 'Interactive Roadmaps & Mentorship',
      description:
          'Follow a personalized, step-by-step career roadmap\nbuilt around your goals.',
      gradient: AppColors.successGradient,
    ),
    OnboardingSlideData(
      icon: Icons.workspace_premium_rounded,
      title: 'Premium Job Matchmaker',
      description:
          'Unlock advanced job matching and land the\nrole that fits you best.',
      gradient: AppColors.premiumGradient,
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToAuth() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _goToAuth,
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.8)),
                    child: const Text('Skip'),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    return PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        double page = _currentPage.toDouble();
                        // PageController.page throws until the PageView has
                        // completed its first layout pass (content dimensions
                        // not established yet on the very first frame).
                        if (_pageController.hasClients) {
                          try {
                            page = _pageController.page ?? page;
                          } catch (_) {
                            // Fall back to _currentPage for this frame.
                          }
                        }
                        final delta = (page - index).clamp(-1.0, 1.0);
                        return OnboardingSlide(
                            data: _slides[index], pageDelta: delta);
                      },
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  double page = _currentPage.toDouble();
                  if (_pageController.hasClients) {
                    try {
                      page = _pageController.page ?? page;
                    } catch (_) {
                      // Fall back to _currentPage for this frame.
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _PageIndicatorDot(
                          closeness: (1 - (page - index).abs().clamp(0.0, 1.0))
                              .clamp(0.0, 1.0)),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  label: _isLastPage ? 'Get Started' : 'Next',
                  onPressed: () {
                    if (_isLastPage) {
                      _goToAuth();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single page-indicator dot whose width/color/scale are driven directly
/// by [closeness] (1.0 = this is the current page, 0.0 = a full page away)
/// rather than snapping between two fixed states after the page settles.
/// Since the parent rebuilds this every scroll frame from the PageView's
/// live position, the dot tracks the user's finger continuously — the
/// "worm" effect premium indicators (Instagram, Airbnb) are known for —
/// instead of only animating once a swipe fully completes.
class _PageIndicatorDot extends StatelessWidget {
  final double closeness;
  const _PageIndicatorDot({required this.closeness});

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(closeness);
    final width = 8.0 + (16.0 * t);
    final scale = 1.0 + (0.15 * t);
    final color = Color.lerp(
      Colors.white.withOpacity(0.28),
      AppColors.primaryDark,
      t,
    )!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: width,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color,
            boxShadow: t > 0.5
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.5 * t),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
