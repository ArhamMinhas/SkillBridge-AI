import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/app_logo_mark.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
import '../../../../core/shared_widgets/glass_card.dart';
import '../../../../core/shared_widgets/google_g_mark.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';
import '../../../../core/shared_widgets/shake_animation.dart';
import '../../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeAnimationState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }

    if (!FirebaseStatus.isAvailable) {
      FeedbackManager.warning(context,
          'Firebase isn\'t configured yet — connect a project to enable login');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      FeedbackManager.success(context, 'Login successful');
      context.go(AppRoutes.dashboard);
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

  Future<void> _handleGoogleLogin() async {
    if (!FirebaseStatus.isAvailable) {
      FeedbackManager.warning(context,
          'Firebase isn\'t configured yet — connect a project to enable Google sign-in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithGoogle();
      if (!mounted) return;
      FeedbackManager.success(context, 'Login successful');
      context.go(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      FeedbackManager.error(context, AuthService.friendlyMessage(e));
    } on PlatformException catch (e) {
      if (!mounted) return;
      debugPrint('Google sign-in PlatformException: ${e.code} — ${e.message}');
      FeedbackManager.error(
          context, AuthService.friendlyGoogleSignInMessage(e));
    } catch (error) {
      if (!mounted) return;
      debugPrint('Google sign-in error: $error');
      FeedbackManager.error(context, 'Something went wrong. Please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
            child: ResponsiveCenter(
              child: EntranceFade(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: AppLogoMark(size: 64)),
                    const SizedBox(height: AppSpacing.xxl),
                    ShakeAnimation(
                      key: _shakeKey,
                      child: GlassCard(
                        brightness: Brightness.dark,
                        child: Theme(
                          data: AppTheme.dark,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back',
                                    style:
                                        AppTextStyles.display1(Colors.white)),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue your career journey',
                                  style: AppTextStyles.bodyMedium(
                                      Colors.white.withOpacity(0.65)),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon:
                                        Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                                opacity: anim, child: child),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_obscurePassword),
                                        ),
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomButton(
                                  label: 'Login',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _handleLogin,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white
                                                .withOpacity(0.15))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text('or',
                                          style: AppTextStyles.caption(
                                              Colors.white.withOpacity(0.5))),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white
                                                .withOpacity(0.15))),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _GoogleButton(
                                  isLoading: _isLoading,
                                  onPressed:
                                      _isLoading ? null : _handleGoogleLogin,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.85)),
                        child: const Text("Don't have an account? Register"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleGMark(size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: AppTextStyles.title(const Color(0xFF1F1F1F)),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
