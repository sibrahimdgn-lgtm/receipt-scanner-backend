import 'dart:ui';

import 'package:flutter/material.dart';

class HoverLiftCard extends StatefulWidget {
  const HoverLiftCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.glowColor = const Color(0xFF00BFA6),
    this.lift = 10,
    this.hoverScale = 1.012,
    this.duration = const Duration(milliseconds: 220),
    this.enableHover = false,
    this.enablePress = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color glowColor;
  final double lift;
  final double hoverScale;
  final Duration duration;
  final bool enableHover;
  final bool enablePress;

  @override
  State<HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<HoverLiftCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active =
        (widget.enableHover && _hovered) || (widget.enablePress && _pressed);
    final progress = active ? 1.0 : 0.0;
    final pressFactor = _pressed ? 0.45 : 1.0;
    final translateY = active ? -(widget.lift * pressFactor) : 0.0;
    final scale = _pressed
        ? 0.992
        : active
            ? widget.hoverScale
            : 1.0;
    final rotateX = widget.enableHover && _hovered ? 0.012 : 0.0;
    final rotateY = widget.enableHover && _hovered ? -0.018 : 0.0;

    Widget result = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final glow = lerpDouble(0, 18, value) ?? 0;
        final spread = lerpDouble(0, 1.5, value) ?? 0;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(0.0, translateY)
          ..scale(scale)
          ..rotateX(rotateX)
          ..rotateY(rotateY);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: value * 0.12),
                  blurRadius: glow,
                  spreadRadius: spread,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: value * 0.18),
                  blurRadius: 24 * value,
                  offset: Offset(0, 16 * value),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );

    if (widget.enablePress) {
      result = Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: result,
      );
    }

    if (widget.enableHover) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: result,
      );
    }

    return result;
  }
}
