import 'package:flutter/material.dart';

class AnimatedBackdrop extends StatelessWidget {
  const AnimatedBackdrop({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF4F5F8),
  });

  final Widget child;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: baseColor,
      child: child,
    );
  }
}
