import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Wraps [child] with a quick press-in/spring-out scale plus the standard
/// ink ripple, and light haptic feedback — the same press language
/// [CustomButton] uses, generalized for tappable cards/list rows that
/// currently only get InkWell's ripple with no scale feedback at all.
class AnimatedTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AnimatedTapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
  });

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: 0.97,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() => _controller.animateTo(0.97,
      duration: const Duration(milliseconds: 90), curve: Curves.easeOut);

  void _release() => _controller.animateTo(1.0,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    // Scale feedback and the ripple both live on the same InkWell gesture
    // callbacks (rather than an outer GestureDetector) so there's only one
    // recognizer in the arena — avoids the ripple/scale racing or dropping
    // taps that a nested GestureDetector + InkWell pairing can cause.
    return ScaleTransition(
      scale: _controller,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTapDown: enabled ? (_) => _press() : null,
          onTapCancel: enabled ? _release : null,
          borderRadius: widget.borderRadius,
          onTap: enabled
              ? () {
                  _release();
                  HapticFeedback.selectionClick();
                  widget.onTap?.call();
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
