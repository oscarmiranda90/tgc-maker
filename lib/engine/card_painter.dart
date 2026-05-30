import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/core/constants.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class CardPainter extends CustomPainter {
  final CardDocument document;
  final TiltState tiltState;
  final Map<String, ui.FragmentProgram> shaderPrograms;
  final Map<String, ui.Image> images;

  const CardPainter({
    required this.document,
    required this.tiltState,
    required this.shaderPrograms,
    required this.images,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(document.cornerRadius),
    );

    canvas.save();
    canvas.clipRRect(cardRect);

    for (final layer in document.sortedLayers) {
      if (!layer.visible) continue;

      final parallax = tiltState.parallaxOffset(
        layer.depthFactor,
        TgcConstants.maxParallaxOffset,
      );

      canvas.save();
      canvas.translate(parallax.dx, parallax.dy);

      if (layer.opacity < 1.0) {
        canvas.saveLayer(
          null,
          Paint()..color = Colors.white.withValues(alpha: layer.opacity),
        );
      }

      switch (layer) {
        case ImageLayer l:
          _drawImageLayer(canvas, size, l);
        case TextLayer l:
          _drawTextLayer(canvas, size, l);
        case ColorLayer l:
          _drawColorLayer(canvas, size, l);
      }

      if (layer.opacity < 1.0) canvas.restore();
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawImageLayer(Canvas canvas, Size size, ImageLayer layer) {
    final img = images[layer.id] ?? images[layer.assetPath ?? ''];
    if (img == null) {
      _drawPlaceholder(canvas, size, layer);
      return;
    }

    final scaleX = size.width * layer.scale / img.width;
    final scaleY = size.height * layer.scale / img.height;
    final s = scaleX > scaleY ? scaleX : scaleY;
    final drawW = img.width * s;
    final drawH = img.height * s;
    final dx = (size.width - drawW) / 2 + layer.position.dx;
    final dy = (size.height - drawH) / 2 + layer.position.dy;

    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    final cropOffX = layer.cropX * iw;
    final cropOffY = layer.cropY * ih;
    final src = Rect.fromLTWH(cropOffX, cropOffY, iw - cropOffX, ih - cropOffY);
    final dst = Rect.fromLTWH(dx, dy, drawW, drawH);

    if (layer.shaderConfig != null && layer.isFoilMask) {
      _drawFoilMask(canvas, size, img, src, dst, layer);
    } else {
      canvas.drawImageRect(img, src, dst, Paint());
      if (layer.shaderConfig != null) {
        _drawShaderOverlay(canvas, size, layer.shaderConfig!);
      }
    }
  }

  void _drawFoilMask(Canvas canvas, Size size, ui.Image img,
      Rect src, Rect dst, ImageLayer layer) {
    final cfg = layer.shaderConfig!;
    final program = shaderPrograms[cfg.shaderAsset];
    if (program == null) {
      canvas.drawImageRect(img, src, dst, Paint());
      return;
    }

    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, tiltState.lightX);
    shader.setFloat(3, tiltState.lightY);
    shader.setFloat(4, tiltState.time);
    if (cfg.sequinsPalette != -1) {
      shader.setFloat(5, cfg.sequinsPalette.toDouble());
    }

    // Layer 1: image as mask stencil
    canvas.saveLayer(null, Paint());
    canvas.drawImageRect(img, src, dst, Paint());

    // Layer 2: shader blended with srcIn (clips to image shape)
    canvas.saveLayer(
      null,
      Paint()..blendMode = BlendMode.srcIn,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
    canvas.restore();

    // Screen overlay for luminosity
    canvas.saveLayer(
      null,
      Paint()
        ..blendMode = BlendMode.screen
        ..color = Colors.white.withValues(alpha: cfg.opacity),
    );
    final shader2 = program.fragmentShader();
    shader2.setFloat(0, size.width);
    shader2.setFloat(1, size.height);
    shader2.setFloat(2, tiltState.lightX);
    shader2.setFloat(3, tiltState.lightY);
    shader2.setFloat(4, tiltState.time);
    if (cfg.sequinsPalette != -1) {
      shader2.setFloat(5, cfg.sequinsPalette.toDouble());
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader2,
    );
    canvas.restore();
    canvas.restore();
  }

  void _drawShaderOverlay(Canvas canvas, Size size, shaderConfig) {
    final program = shaderPrograms[shaderConfig.shaderAsset];
    if (program == null) return;
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, tiltState.lightX);
    shader.setFloat(3, tiltState.lightY);
    shader.setFloat(4, tiltState.time);
    if (shaderConfig.sequinsPalette != -1) {
      shader.setFloat(5, shaderConfig.sequinsPalette.toDouble());
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = shader
        ..blendMode = shaderConfig.blendMode
        ..color = Colors.white.withValues(alpha: shaderConfig.opacity),
    );
  }

  void _drawTextLayer(Canvas canvas, Size size, TextLayer layer) {
    final style = ui.ParagraphStyle(
      textAlign: layer.align,
      maxLines: 5,
    );
    final builder = ui.ParagraphBuilder(style)
      ..pushStyle(ui.TextStyle(
        color: layer.color,
        fontSize: layer.fontSize * layer.scale,
        fontWeight: layer.fontWeight,
      ))
      ..addText(layer.text);
    final para = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 32));

    final dx = 16.0 + layer.position.dx;
    final dy = (size.height - para.height) / 2 + layer.position.dy;
    canvas.drawParagraph(para, Offset(dx, dy));
  }

  void _drawColorLayer(Canvas canvas, Size size, ColorLayer layer) {
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        layer.position.dx,
        layer.position.dy,
        size.width * layer.scale,
        size.height * layer.scale,
      ),
      topLeft: layer.borderRadius.topLeft,
      topRight: layer.borderRadius.topRight,
      bottomLeft: layer.borderRadius.bottomLeft,
      bottomRight: layer.borderRadius.bottomRight,
    );
    canvas.drawRRect(rect, Paint()..color = layer.color);
  }

  void _drawPlaceholder(Canvas canvas, Size size, ImageLayer layer) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1C1C28),
    );
  }

  @override
  bool shouldRepaint(CardPainter old) =>
      old.tiltState != tiltState ||
      old.document != document ||
      old.images != images;
}
