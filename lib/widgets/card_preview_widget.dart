import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/engine/card_painter.dart';
import 'package:tgc_maker/engine/gloss_painter.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/parallax/parallax_card.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class CardPreviewWidget extends StatelessWidget {
  final CardDocument document;
  final Map<String, ui.FragmentProgram> shaderPrograms;
  final Map<String, ui.Image> images;
  final double maxWidth;
  final double maxHeight;
  final bool enableParallax;

  const CardPreviewWidget({
    super.key,
    required this.document,
    required this.shaderPrograms,
    this.images = const {},
    this.maxWidth = 280,
    this.maxHeight = 420,
    this.enableParallax = true,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = document.size.aspectRatio;
    double w = maxWidth;
    double h = w / aspect;
    if (h > maxHeight) {
      h = maxHeight;
      w = h * aspect;
    }

    if (!enableParallax) {
      return _buildCardStack(TiltState.zero, w, h);
    }

    return ParallaxCard(
      width: w,
      height: h,
      builder: (tilt) => _buildCardStack(tilt, w, h),
    );
  }

  Widget _buildCardStack(TiltState tilt, double w, double h) {
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: CardPainter(
              document: document,
              tiltState: tilt,
              shaderPrograms: shaderPrograms,
              images: images,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GlossPainter(
                lightX: tilt.lightX,
                lightY: tilt.lightY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
