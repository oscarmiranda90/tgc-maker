import 'package:flutter/material.dart';

class GlossPainter extends CustomPainter {
  final double lightX;
  final double lightY;

  const GlossPainter({required this.lightX, required this.lightY});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = (lightX * 0.5 + 0.5) * size.width;
    final cy = (lightY * 0.5 + 0.5) * size.height;

    final gradient = RadialGradient(
      center: Alignment(lightX, lightY),
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Specular hotspot
    final specPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(cx, cy), 80, specPaint);
  }

  @override
  bool shouldRepaint(GlossPainter old) =>
      old.lightX != lightX || old.lightY != lightY;
}
