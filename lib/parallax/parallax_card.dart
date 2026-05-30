import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tgc_maker/core/constants.dart';
import 'package:tgc_maker/parallax/tilt_controller.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class ParallaxCard extends StatefulWidget {
  final double width;
  final double height;
  final Widget Function(TiltState tilt) builder;

  const ParallaxCard({
    super.key,
    required this.width,
    required this.height,
    required this.builder,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard>
    with TickerProviderStateMixin {
  late final TiltController _controller;
  TiltState _tiltState = TiltState.zero;
  StreamSubscription<TiltState>? _sub;

  late AnimationController _returnController;
  late Animation<double> _animTiltX;
  late Animation<double> _animTiltY;
  late Animation<double> _animLightX;
  late Animation<double> _animLightY;
  bool _isDragging = false;
  double _dragTiltX = 0.0;
  double _dragTiltY = 0.0;
  double _dragLightX = 0.0;
  double _dragLightY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TiltController()..start(this);
    _sub = _controller.stream.listen((s) {
      if (!_isDragging && !_returnController.isAnimating) {
        setState(() => _tiltState = s);
      }
    });

    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animTiltX = const AlwaysStoppedAnimation(0.0);
    _animTiltY = const AlwaysStoppedAnimation(0.0);
    _animLightX = const AlwaysStoppedAnimation(0.0);
    _animLightY = const AlwaysStoppedAnimation(0.0);

    _returnController.addListener(() {
      if (!_isDragging) {
        setState(() {
          _tiltState = TiltState(
            tiltX: _animTiltX.value,
            tiltY: _animTiltY.value,
            lightX: _animLightX.value,
            lightY: _animLightY.value,
            time: _tiltState.time,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _returnController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    _isDragging = true;
    _returnController.stop();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(d.globalPosition);
    final nx = ((local.dx / widget.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((local.dy / widget.height) * 2 - 1).clamp(-1.0, 1.0);
    _dragTiltX = -ny * TgcConstants.maxTilt;
    _dragTiltY = nx * TgcConstants.maxTilt;
    _dragLightX = nx;
    _dragLightY = ny;
    setState(() {
      _tiltState = TiltState(
        tiltX: _dragTiltX,
        tiltY: _dragTiltY,
        lightX: _dragLightX,
        lightY: _dragLightY,
        time: _tiltState.time,
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _isDragging = false;
    final curve = CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutCubic,
    );
    _animTiltX = Tween<double>(begin: _dragTiltX, end: 0.0).animate(curve);
    _animTiltY = Tween<double>(begin: _dragTiltY, end: 0.0).animate(curve);
    _animLightX = Tween<double>(begin: _dragLightX, end: 0.0).animate(curve);
    _animLightY = Tween<double>(begin: _dragLightY, end: 0.0).animate(curve);
    _returnController.forward(from: 0);
    _controller.resetToGyro();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltState.tiltX)
          ..rotateY(_tiltState.tiltY),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TgcConstants.cardCornerRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TgcConstants.cardCornerRadius),
            child: widget.builder(_tiltState),
          ),
        ),
      ),
    );
  }
}
