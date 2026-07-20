import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
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
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final muted = Theme.of(context).hintColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: ShakeAnimation(
                key: _shakeKey,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back',
                          style: AppTextStyles.display1(textColor)),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your career journey',
                        style: AppTextStyles.bodyMedium(muted),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
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
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Login',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Theme.of(context).dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child:
                                Text('or', style: AppTextStyles.caption(muted)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Theme.of(context).dividerColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Continue with Google',
                        variant: ButtonVariant.outline,
                        icon: Icons.g_mobiledata_rounded,
                        isLoading: false,
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.register),
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
      ),
    );
  }
}
