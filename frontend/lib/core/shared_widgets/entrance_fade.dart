import 'package:flutter/material.dart';

/// Fades + slides its child up on mount. Stack a few of these with
/// increasing [delay] to get a cheap cascading/staggered entrance without
/// hand-rolling an AnimationController + Interval set per screen.
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
