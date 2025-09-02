import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final double additionalOffset;
  final Widget child;

  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.additionalOffset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1.0 - animation.value) * (additionalOffset + 30.0)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
