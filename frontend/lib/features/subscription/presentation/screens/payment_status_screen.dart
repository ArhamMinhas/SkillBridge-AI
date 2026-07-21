import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/glass_card.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';

/// Full-screen payment result — deliberately uses the same ambient
/// ([MeshGradientBackground] + [GlassCard]) language as Splash/Login/Register
/// rather than a plain scaffold, since this is a first-impression interstitial
/// in its own right, not a nested dashboard page.
class PaymentStatusScreen extends StatelessWidget {
  final bool success;

  const PaymentStatusScreen({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ResponsiveCenter(
                child: GlassCard(
                  brightness: Brightness.dark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl, vertical: AppSpacing.huge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusIcon(success: success),
                      const SizedBox(height: AppSpacing.xxl),
                      EntranceFade(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          success ? 'You\'re Premium!' : 'Payment Failed',
                          style: AppTextStyles.display1(Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      EntranceFade(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          success
                              ? 'Welcome to SkillBridge Pro. All AI features are '
                                  'now unlocked — let\'s put them to work.'
                              : 'Your payment couldn\'t be processed. No charge '
                                  'was made — please try again.',
                          style: AppTextStyles.bodyMedium(
                              Colors.white.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      EntranceFade(
                        delay: const Duration(milliseconds: 420),
                        child: CustomButton(
                          label: success ? 'Go to Dashboard' : 'Try Again',
                          gradient: success
                              ? AppColors.primaryGradient
                              : AppColors.premiumGradient,
                          onPressed: () => success
                              ? context.go(AppRoutes.dashboard)
                              : context.go(AppRoutes.premiumSubscription),
                        ),
                      ),
                      if (!success) ...[
                        const SizedBox(height: 12),
                        EntranceFade(
                          delay: const Duration(milliseconds: 500),
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.dashboard),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.8)),
                            child: const Text('Maybe later'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient badge with a spring-in checkmark/cross, a continuous soft pulse
/// ring, and — on success only — a one-shot outward sparkle burst.
class _StatusIcon extends StatefulWidget {
  final bool success;
  const _StatusIcon({required this.success});

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _burst.forward();
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.success
        ? AppColors.successGradient
        : const LinearGradient(
            colors: [AppColors.errorDark, AppColors.warningDark]);
    final glowColor = widget.success ? AppColors.successDark : AppColors.errorDark;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.success)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) => CustomPaint(
                  painter: _SparklePainter(progress: _burst.value),
                  size: const Size(180, 180),
                ),
              ),
            ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final scale = 1.0 + _pulse.value * 0.18;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor.withOpacity(0.16 * (1 - _pulse.value * 0.5)),
                    ),
                  ),
                );
              },
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(glowColor, opacity: 0.4),
              ),
              child: Icon(
                widget.success ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle {
  final double angle;
  final double distanceFactor;
  const _Sparkle(this.angle, this.distanceFactor);
}

final List<_Sparkle> _sparkles = List.generate(10, (i) {
  final angle = (i / 10) * 2 * math.pi;
  final rnd = math.Random(i * 13);
  return _Sparkle(angle, 0.7 + rnd.nextDouble() * 0.5);
});

class _SparklePainter extends CustomPainter {
  final double progress;
  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (final s in _sparkles) {
      final dist = progress * size.width * 0.5 * s.distanceFactor;
      final pos = center + Offset(math.cos(s.angle), math.sin(s.angle)) * dist;
      paint.color = AppColors.successDark.withOpacity(fade * 0.8);
      canvas.drawCircle(pos, 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
