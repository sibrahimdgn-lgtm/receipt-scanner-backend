import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF8FBFD),
    this.topColor = const Color(0xFFF0F6FA),
    this.accentColor = const Color(0xFF13B5EA),
    this.secondaryAccentColor = const Color(0xFF1678C2),
  });

  final Widget child;
  final Color baseColor;
  final Color topColor;
  final Color accentColor;
  final Color secondaryAccentColor;

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = math.max(
              320.0,
              math.min(constraints.maxWidth, constraints.maxHeight),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.baseColor,
                        widget.topColor,
                        Color.lerp(widget.topColor, widget.baseColor, 0.72)!,
                        widget.baseColor,
                      ],
                    ),
                  ),
                ),
                _orb(
                  size: shortestSide * 0.56,
                  alignment: Alignment(-1.14 + (t * 0.08), -1.04),
                  color: widget.accentColor.withValues(alpha: 0.22),
                  dx: 18,
                  dy: 10,
                  phase: 0,
                ),
                _orb(
                  size: shortestSide * 0.48,
                  alignment: Alignment(1.08 - (t * 0.06), -0.22),
                  color: widget.secondaryAccentColor.withValues(alpha: 0.18),
                  dx: 12,
                  dy: 16,
                  phase: math.pi / 2,
                ),
                child!,
              ],
            );
          },
        );
      },
      child: widget.child,
    );
  }

  Widget _orb({
    required double size,
    required Alignment alignment,
    required Color color,
    required double dx,
    required double dy,
    required double phase,
  }) {
    final wave = (_controller.value * math.pi * 2) + phase;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: Offset(
            math.sin(wave) * dx,
            math.cos(wave) * dy,
          ),
          child: Transform.scale(
            scale: 0.94 + (((math.sin(wave) + 1) / 2) * 0.08),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    Colors.transparent,
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
