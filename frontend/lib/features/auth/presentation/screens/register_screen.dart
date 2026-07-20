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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeAnimationState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }

    if (!FirebaseStatus.isAvailable) {
      FeedbackManager.warning(context,
          'Firebase isn\'t configured yet — connect a project to enable registration');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await credential.user?.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      FeedbackManager.success(context, 'Registration successful');
      context.go(AppRoutes.profileSetup);
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
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: ShakeAnimation(
                key: _shakeKey,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join SkillBridge AI',
                          style: AppTextStyles.display1(textColor)),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to start your AI-powered career journey',
                        style: AppTextStyles.bodyMedium(muted),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => Validators.required(v, label: 'Name'),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) => Validators.confirmPassword(
                            v, _passwordController.text),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Create Account',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleRegister,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Already have an account? Login'),
                        ),
                      ),
                      const SizedBox(height: 20),
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
