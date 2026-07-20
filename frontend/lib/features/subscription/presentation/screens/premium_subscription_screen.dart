import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/utils/responsive.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/shared_widgets/custom_button.dart';
import '../../../../core/shared_widgets/entrance_fade.dart';

const _features = [
  'Unlimited resume analyses',
  'Unlimited AI mock interviews',
  'Priority job match scoring',
  'Full career roadmap & skill gap reports',
  'Ad-free experience',
];

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final _paymentService = PaymentService();
  bool _isYearly = true;
  bool _isProcessing = false;

  Future<void> _subscribe() async {
    setState(() => _isProcessing = true);
    try {
      await _paymentService.purchasePremium(
          plan: _isYearly ? 'PRO_YEARLY' : 'PRO');
      if (!mounted) return;
      context.go(AppRoutes.paymentSuccess);
    } on StripeException catch (e) {
      final canceled = e.error.code == FailureCode.Canceled;
      if (canceled) return;
      if (!mounted) return;
      context.go(AppRoutes.paymentFailure);
    } catch (_) {
      if (!mounted) return;
      context.go(AppRoutes.paymentFailure);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: EntranceFade(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('Unlock SkillBridge Pro',
                      style: AppTextStyles.heading1(textColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Get unlimited access to every AI-powered feature and '
                    'accelerate your career growth.',
                    style:
                        AppTextStyles.bodyMedium(Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 28),
                  _PlanToggle(
                    isYearly: _isYearly,
                    onChanged: (v) => setState(() => _isYearly = v),
                  ),
                  const SizedBox(height: 28),
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.successDark.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: AppColors.successDark, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(f,
                                    style:
                                        AppTextStyles.bodyMedium(textColor))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: _isYearly
                        ? 'Subscribe — \$89.99/year'
                        : 'Subscribe — \$9.99/month',
                    gradient: AppColors.premiumGradient,
                    icon: Icons.workspace_premium_rounded,
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _subscribe,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Cancel anytime from Settings.',
                      style: AppTextStyles.caption(Theme.of(context).hintColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const _PlanToggle({required this.isYearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
              child: _ToggleOption(
                  label: 'Monthly',
                  selected: !isYearly,
                  onTap: () => onChanged(false))),
          Expanded(
            child: _ToggleOption(
              label: 'Yearly',
              badge: 'Save 25%',
              selected: isYearly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null)
              Text(
                badge!,
                style: TextStyle(
                  color: selected ? Colors.white70 : primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
