import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/shared_widgets/app_logo_mark.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Drives the one-shot staggered entrance (logo -> title -> tagline -> progress).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Loops for as long as the splash is on screen: pulse rings + breathing glow.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
  late final Animation<double> _logoOpacity = CurvedAnimation(
      parent: _entrance, curve: const Interval(0.0, 0.4, curve: Curves.easeIn));
  late final Animation<double> _titleProgress = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic));
  late final Animation<double> _taglineOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn));
  late final Animation<double> _progressOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _resolveNextRoute();
  }

  Future<void> _resolveNextRoute() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1900)),
      _isAuthenticated(),
    ]).then((results) {
      if (!mounted) return;
      final isAuthenticated = results[1] as bool;
      context.go(isAuthenticated ? AppRoutes.dashboard : AppRoutes.onboarding);
    });
  }

  Future<bool> _isAuthenticated() async {
    if (!FirebaseStatus.isAvailable) return false;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = responsiveSize(context, fraction: 0.26, min: 88, max: 140);
    final ringBoxSize = logoSize * 1.9;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const MeshGradientBackground(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: ringBoxSize,
                    height: ringBoxSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) => _PulseRing(
                              progress: _pulse.value,
                              phaseOffset: 0.0,
                              baseSize: logoSize * 1.35),
                        ),
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) => _PulseRing(
                              progress: _pulse.value,
                              phaseOffset: 0.5,
                              baseSize: logoSize * 1.35),
                        ),
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: AppLogoMark(size: logoSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.4), end: Offset.zero)
                        .animate(_titleProgress),
                    child: FadeTransition(
                      opacity: _titleProgress,
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          'SkillBridge AI',
                          style: AppTextStyles.display1(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      'AI-Powered Career Growth',
                      style: AppTextStyles.bodyMedium(
                          Colors.white.withOpacity(0.72)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: _progressOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.secondaryDark),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Checking your session...',
                      style:
                          AppTextStyles.caption(Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single expanding-and-fading ring — two instances at opposite phase
/// offsets create a continuous "radar ping" effect around the logo.
class _PulseRing extends StatelessWidget {
  final double progress; // 0..1, loops
  final double phaseOffset;
  final double baseSize;

  const _PulseRing(
      {required this.progress,
      required this.phaseOffset,
      required this.baseSize});

  @override
  Widget build(BuildContext context) {
    final t = (progress + phaseOffset) % 1.0;
    final scale = 0.6 + (t * 0.9);
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondaryDark, width: 1.5),
          ),
        ),
      ),
    );
  }
}
