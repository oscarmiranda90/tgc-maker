import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A two-sided 3D Y-axis flip. The card rotates a half-turn; at the edge-on
/// midpoint the content swap happens, so the new face is never seen mirrored.
///
/// [showBack] is the desired side. While animating to it, [builder] is called
/// with the side that should currently be painted — this lets the parent swap
/// the active face exactly when the card is edge-on (invisible).
class FlipCard extends StatefulWidget {
  final bool showBack;
  final Widget Function(BuildContext context, bool showingBack) builder;
  final Duration duration;

  const FlipCard({
    super.key,
    required this.showBack,
    required this.builder,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // The side currently painted. Swapped at the edge-on midpoint.
  late bool _paintingBack;

  @override
  void initState() {
    super.initState();
    _paintingBack = widget.showBack;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.showBack ? 1.0 : 0.0,
    )..addListener(_handleTick);
  }

  void _handleTick() {
    // Swap the painted content once the card passes the edge-on point.
    final shouldPaintBack = _controller.value > 0.5;
    if (shouldPaintBack != _paintingBack) {
      setState(() => _paintingBack = shouldPaintBack);
    }
  }

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.showBack != old.showBack) {
      if (widget.showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * math.pi;
        // Keep the painted face upright: once we're showing the back content
        // (past halfway), offset by pi so it isn't mirror-rotated.
        final contentAngle = _paintingBack ? angle - math.pi : angle;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // perspective
          ..rotateY(contentAngle);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: widget.builder(context, _paintingBack),
        );
      },
    );
  }
}
