import 'package:flutter/material.dart';

class EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset offset;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 16),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1.0 - value),
              offset.dy * (1.0 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
