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
import '../../../../core/shared_widgets/glass_card.dart';
import '../../../../core/shared_widgets/mesh_gradient_background.dart';
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
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateStrength);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final text = _passwordController.text;
    var score = 0.0;
    if (text.length >= 8) score += 0.25;
    if (text.length >= 12) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(text) && RegExp(r'[a-z]').hasMatch(text)) {
      score += 0.25;
    }
    if (RegExp(r'[0-9]').hasMatch(text) || RegExp(r'[^\w\s]').hasMatch(text)) {
      score += 0.25;
    }
    setState(() => _passwordStrength = score);
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Join SkillBridge AI',
                                style: AppTextStyles.display1(Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                              'Create an account to start your AI-powered '
                              'career journey',
                              style: AppTextStyles.bodyMedium(
                                  Colors.white.withOpacity(0.65)),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            TextFormField(
                              controller: _nameController,
                              autofillHints: const [AutofillHints.name],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) =>
                                  Validators.required(v, label: 'Name'),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: Validators.password,
                            ),
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _PasswordStrengthBar(strength: _passwordStrength),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
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
                            const SizedBox(height: AppSpacing.xxl),
                            CustomButton(
                              label: 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _handleRegister,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        Colors.white.withOpacity(0.85)),
                                child: const Text(
                                    'Already have an account? Login'),
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
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  const _PasswordStrengthBar({required this.strength});

  Color _color() {
    if (strength <= 0.25) return AppColors.errorDark;
    if (strength <= 0.5) return AppColors.warningDark;
    if (strength <= 0.75) return const Color(0xFF60A5FA);
    return AppColors.successDark;
  }

  String _label() {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: strength),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(_label(),
            style: AppTextStyles.caption(color)
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
