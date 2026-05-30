import 'package:flutter/material.dart';

class TiltState {
  final double tiltX;
  final double tiltY;
  final double lightX;
  final double lightY;
  final double time;

  const TiltState({
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.lightX = 0.0,
    this.lightY = 0.0,
    this.time = 0.0,
  });

  Offset parallaxOffset(double depthFactor, double maxOffset) => Offset(
        lightX * maxOffset * depthFactor,
        lightY * maxOffset * depthFactor,
      );

  static const zero = TiltState();

  @override
  bool operator ==(Object other) =>
      other is TiltState &&
      tiltX == other.tiltX &&
      tiltY == other.tiltY &&
      lightX == other.lightX &&
      lightY == other.lightY &&
      time == other.time;

  @override
  int get hashCode => Object.hash(tiltX, tiltY, lightX, lightY, time);
}
