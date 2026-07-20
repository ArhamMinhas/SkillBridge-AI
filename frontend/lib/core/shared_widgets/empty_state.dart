import 'package:flutter/material.dart';
import '../../app/config/theme.dart';
import 'custom_button.dart';

/// Reusable illustrated empty state for lists/screens with no data.
/// Pass an icon (or swap for a Lottie/SVG asset later) plus title/subtitle.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).hintColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient.withOpacityAll(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: AppTextStyles.heading2(
                    Theme.of(context).textTheme.bodyLarge!.color!),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: AppTextStyles.bodyMedium(muted),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: ButtonVariant.outline),
            ],
          ],
        ),
      ),
    );
  }
}

extension on Gradient {
  Gradient withOpacityAll(double opacity) {
    if (this is LinearGradient) {
      final g = this as LinearGradient;
      return LinearGradient(
        begin: g.begin,
        end: g.end,
        colors: g.colors.map((c) => c.withOpacity(opacity)).toList(),
      );
    }
    return this;
  }
}
