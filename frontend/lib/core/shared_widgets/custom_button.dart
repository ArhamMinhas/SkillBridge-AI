import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../app/config/theme.dart';

enum ButtonVariant { gradient, outline, plain }

/// Gradient/outline button with a springy press micro-interaction (quick
/// press-in, elastic bounce-back on release) plus a soft color-matched glow
/// behind gradient buttons — the app's primary call-to-action treatment.
class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Gradient gradient;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.gradient,
    this.isLoading = false,
    this.icon,
    this.gradient = AppColors.primaryGradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: 0.94,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _press() {
    HapticFeedback.selectionClick();
    _controller.animateTo(0.94,
        duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _release() {
    _controller.animateTo(1.0,
        duration: const Duration(milliseconds: 380), curve: Curves.elasticOut);
  }

  Color get _glowColor => widget.gradient is LinearGradient
      ? (widget.gradient as LinearGradient).colors.first
      : Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    final isGradient = widget.variant == ButtonVariant.gradient;

    final child = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isGradient ? widget.gradient : null,
        color: widget.variant == ButtonVariant.plain
            ? Theme.of(context).primaryColor
            : null,
        border: widget.variant == ButtonVariant.outline
            ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: isGradient && _enabled
            ? AppShadows.glow(_glowColor, opacity: 0.35)
            : null,
      ),
      child: widget.isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon,
                      color: widget.variant == ButtonVariant.outline
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.variant == ButtonVariant.outline
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );

    return Opacity(
      opacity: _enabled ? 1.0 : 0.6,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _press() : null,
        onTapUp: _enabled
            ? (_) {
                _release();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? _release : null,
        child: ScaleTransition(scale: _controller, child: child),
      ),
    );
  }
}
