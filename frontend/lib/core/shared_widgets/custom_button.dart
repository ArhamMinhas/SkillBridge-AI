import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

enum ButtonVariant { gradient, outline, plain }

/// Gradient/outline button with a scale-down-and-up press micro-interaction,
/// per docs/frontend_design_spec.md section 3.B (AnimatedTapHandler pattern).
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
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient:
            widget.variant == ButtonVariant.gradient ? widget.gradient : null,
        color: widget.variant == ButtonVariant.plain
            ? Theme.of(context).primaryColor
            : null,
        border: widget.variant == ButtonVariant.outline
            ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
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
        onTapDown: _enabled ? (_) => _controller.reverse() : null,
        onTapUp: _enabled
            ? (_) {
                _controller.forward();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? () => _controller.forward() : null,
        child: ScaleTransition(scale: _controller, child: child),
      ),
    );
  }
}
