import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class MotionReveal extends StatefulWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 720),
    this.beginOffset = const Offset(0, 0.08),
    this.beginScale = 0.97,
    this.beginTilt = 0.045,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;
  final double beginTilt;
  final Curve curve;

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final dx = widget.beginOffset.dx * (1 - t);
        final dy = widget.beginOffset.dy * (1 - t);
        final scale = widget.beginScale + ((1 - widget.beginScale) * t);
        final tilt = widget.beginTilt * (1 - t);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(dx * 120, dy * 120)
          ..scale(scale)
          ..rotateX(-tilt)
          ..rotateY(tilt * 0.6);

        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
