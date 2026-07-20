import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/firebase_status.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../app/utils/validators.dart';
import '../../../../core/shared_widgets/animated_toast.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';
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
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final muted = Theme.of(context).hintColor;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Padding(
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
                      Text('Reset your password',
                          style: AppTextStyles.heading1(textColor)),
                      const SizedBox(height: 8),
                      Text(
                        "Enter the email associated with your account and we'll send a link to reset your password.",
                        style: AppTextStyles.bodyMedium(muted),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                          suffixIcon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isEmailValid
                                ? const Icon(Icons.check_circle_rounded,
                                    key: ValueKey('valid'),
                                    color: AppColors.successLight)
                                : const SizedBox.shrink(
                                    key: ValueKey('invalid')),
                          ),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: _linkSent
                            ? 'Resend Recovery Link'
                            : 'Send Recovery Link',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSendLink,
                      ),
                      if (_linkSent) ...[
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                                scale: 0.9 + (0.1 * value), child: child),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.successLight, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recovery link sent to ${_emailController.text.trim()}',
                                  style: AppTextStyles.bodyMedium(muted),
                                ),
                              ),
                            ],
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
