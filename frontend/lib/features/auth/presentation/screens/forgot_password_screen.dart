import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/glass_card.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';
import '../../../../core/shared_widgets/shake_animation.dart';
import '../../../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeAnimationState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _linkSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final valid = Validators.email(_emailController.text) == null;
      if (valid != _isEmailValid) setState(() => _isEmailValid = valid);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendLink() async {
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }

    if (!FirebaseStatus.isAvailable) {
      FeedbackManager.warning(context,
          'Firebase isn\'t configured yet — connect a project to enable this');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _linkSent = true);
      FeedbackManager.success(context, 'Recovery link sent — check your inbox');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      FeedbackManager.error(context, AuthService.friendlyMessage(e));
    } catch (_) {
      if (!mounted) return;
      FeedbackManager.error(
          context, 'Network unavailable. Check your connection');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MeshGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            child: ResponsiveCenter(
              child: EntranceFade(
                child: ShakeAnimation(
                  key: _shakeKey,
                  child: GlassCard(
                    brightness: Brightness.dark,
                    child: Theme(
                      data: AppTheme.dark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: _HeroIcon(sent: _linkSent)),
                          const SizedBox(height: AppSpacing.xxl),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.06),
                                        end: Offset.zero)
                                    .animate(anim),
                                child: child,
                              ),
                            ),
                            child: _linkSent
                                ? _SentBody(
                                    key: const ValueKey('sent'),
                                    email: _emailController.text.trim(),
                                    isLoading: _isLoading,
                                    onResend: _handleSendLink,
                                  )
                                : _FormBody(
                                    key: const ValueKey('form'),
                                    formKey: _formKey,
                                    emailController: _emailController,
                                    isEmailValid: _isEmailValid,
                                    isLoading: _isLoading,
                                    onSend: _handleSendLink,
                                  ),
                          ),
                        ],
                      ),
                    ),
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

/// Floating, gently glowing icon badge — envelope while waiting, checkmark
/// once the link has been sent, cross-fading between the two.
class _HeroIcon extends StatefulWidget {
  final bool sent;
  const _HeroIcon({required this.sent});

  @override
  State<_HeroIcon> createState() => _HeroIconState();
}

class _HeroIconState extends State<_HeroIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.sent ? AppColors.successDark : AppColors.primaryDark;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final bob = (_float.value - 0.5) * 6;
          return Transform.translate(offset: Offset(0, bob), child: child);
        },
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: widget.sent
                ? AppColors.successGradient
                : AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow(color, opacity: 0.4),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child)),
            child: Icon(
              widget.sent
                  ? Icons.mark_email_read_rounded
                  : Icons.lock_reset_rounded,
              key: ValueKey(widget.sent),
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isEmailValid;
  final bool isLoading;
  final VoidCallback onSend;

  const _FormBody({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isEmailValid,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reset your password',
              style: AppTextStyles.heading1(Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            "Enter the email associated with your account and we'll send a "
            "link to reset your password.",
            style: AppTextStyles.bodyMedium(Colors.white.withOpacity(0.65)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              suffixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isEmailValid
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('valid'), color: AppColors.successDark)
                    : const SizedBox.shrink(key: ValueKey('invalid')),
              ),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.xxl),
          CustomButton(
            label: 'Send Recovery Link',
            isLoading: isLoading,
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _SentBody extends StatelessWidget {
  final String email;
  final bool isLoading;
  final VoidCallback onResend;

  const _SentBody({
    super.key,
    required this.email,
    required this.isLoading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check your inbox',
            style: AppTextStyles.heading1(Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'We sent a recovery link to $email. Follow it to choose a new '
          'password — the link expires soon, so use it within the hour.',
          style: AppTextStyles.bodyMedium(Colors.white.withOpacity(0.65)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Resend Link',
          variant: ButtonVariant.outline,
          isLoading: isLoading,
          onPressed: isLoading ? null : onResend,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            style:
                TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.85)),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}
