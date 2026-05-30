import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Uniform contract (all shaders):
//   0: uResolution.x
//   1: uResolution.y
//   2: uLightPos.x  [-1, 1]
//   3: uLightPos.y  [-1, 1]
//   4: uTime
//   5: uPalette     (sequins only, -1 = random)
class ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double width;
  final double height;
  final double lightX;
  final double lightY;
  final double time;
  final int sequinsPalette;

  const ShaderPainter({
    required this.shader,
    required this.width,
    required this.height,
    required this.lightX,
    required this.lightY,
    required this.time,
    this.sequinsPalette = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, lightX);
    shader.setFloat(3, lightY);
    shader.setFloat(4, time);
    if (sequinsPalette != -1) {
      shader.setFloat(5, sequinsPalette.toDouble());
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(ShaderPainter old) =>
      old.lightX != lightX ||
      old.lightY != lightY ||
      old.time != time ||
      old.sequinsPalette != sequinsPalette;
}
