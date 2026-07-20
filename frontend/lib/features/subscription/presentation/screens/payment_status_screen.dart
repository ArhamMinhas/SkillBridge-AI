import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

class PaymentStatusScreen extends StatelessWidget {
  final bool success;

  const PaymentStatusScreen({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ResponsiveCenter(
              child: EntranceFade(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: success
                            ? AppColors.successGradient
                            : const LinearGradient(
                                colors: [
                                  AppColors.errorDark,
                                  AppColors.warningDark
                                ],
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        success ? Icons.check_rounded : Icons.close_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      success ? 'You\'re Premium!' : 'Payment Failed',
                      style: AppTextStyles.heading1(textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      success
                          ? 'Welcome to SkillBridge Pro. All AI features are '
                              'now unlocked — let\'s put them to work.'
                          : 'Your payment couldn\'t be processed. No charge '
                              'was made — please try again.',
                      style:
                          AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      label: success ? 'Go to Dashboard' : 'Try Again',
                      gradient: success
                          ? AppColors.primaryGradient
                          : AppColors.premiumGradient,
                      onPressed: () => success
                          ? context.go(AppRoutes.dashboard)
                          : context.go(AppRoutes.premiumSubscription),
                    ),
                    if (!success) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.dashboard),
                        child: const Text('Maybe later'),
                      ),
                    ],
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
