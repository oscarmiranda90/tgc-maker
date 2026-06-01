import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/core/constants.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/engine/text_fonts.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class CardPainter extends CustomPainter {
  static const double maxFrameOutset = 20.0;

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

  /// How far the outer frame eats inward from the card edge (logical pixels).
  /// Layers are laid out inside this border, but the card size never changes.
  static double frameBorderForDocument(CardDocument document) {
    final frame = document.frameConfig;
    if (frame == null || !frame.visible) return 0.0;
    return frame.thickness.clamp(0.0, maxFrameOutset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final frame = document.frameConfig;
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(document.cornerRadius),
    );

    // The outer frame thickness eats inward from the card edge; layers fill
    // the remaining inner area. Card size never changes (no zoom).
    final border = frameBorderForDocument(document);
    final contentRect = Rect.fromLTWH(
      border,
      border,
      (size.width - border * 2).clamp(0.0, size.width),
      (size.height - border * 2).clamp(0.0, size.height),
    );
    final contentRRect = RRect.fromRectAndRadius(
      contentRect,
      Radius.circular(
        (document.cornerRadius - border).clamp(0.0, double.infinity),
      ),
    );

    final frameVisible = frame != null && frame.visible;

    canvas.save();
    canvas.clipRRect(cardRRect);

    // Pass 1: background + art layers (below the frame).
    canvas.save();
    canvas.clipRRect(contentRRect);
    canvas.translate(contentRect.left, contentRect.top);
    _paintLayers(canvas, contentRect.size, const {
      LayerGroup.background,
      LayerGroup.art,
    });
    canvas.restore();

    // The frame (outer border + inward band) sits above art, below layout.
    if (frameVisible && border > 0) {
      _drawFrame(canvas, size, contentRect, 0.0, frame);
    }
    // Pass 2: layout layers (above the frame).
    canvas.save();
    canvas.clipRRect(contentRRect);
    canvas.translate(contentRect.left, contentRect.top);
    _paintLayers(canvas, contentRect.size, const {LayerGroup.layout});
    canvas.restore();

    // Draw the inward band last so it remains visible above layout elements.
    if (frameVisible && frame.inwardThickness > 0) {
      _drawInwardBand(canvas, size, contentRect, frame);
    }

    canvas.restore();
  }

  void _paintLayers(Canvas canvas, Size size, Set<LayerGroup> groups) {
    for (final layer in document.sortedLayers) {
      if (!layer.visible) continue;
      if (!groups.contains(layer.group)) continue;

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
    final cropX = layer.cropX.clamp(0.0, 0.95);
    final cropY = layer.cropY.clamp(0.0, 0.95);
    final visibleW = drawW * (1 - cropX);
    final visibleH = drawH * (1 - cropY);
    final clipRect = Rect.fromLTWH(
      dx + (drawW - visibleW) / 2,
      dy + (drawH - visibleH) / 2,
      visibleW,
      visibleH,
    );
    final src = Rect.fromLTWH(0, 0, iw, ih);
    final dst = Rect.fromLTWH(dx, dy, drawW, drawH);

    canvas.save();
    canvas.clipRect(clipRect);
    if (layer.shaderConfig != null && layer.isFoilMask) {
      _drawFoilMask(canvas, size, img, src, dst, layer);
    } else {
      canvas.drawImageRect(img, src, dst, Paint());
      if (layer.shaderConfig != null) {
        _drawShaderOverlay(canvas, size, layer.shaderConfig!);
      }
    }
    canvas.restore();
  }

  void _drawFoilMask(
    Canvas canvas,
    Size size,
    ui.Image img,
    Rect src,
    Rect dst,
    ImageLayer layer,
  ) {
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
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.srcIn);
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
    final style = ui.ParagraphStyle(textAlign: layer.align, maxLines: 5);
    final builder = ui.ParagraphBuilder(style)
      ..pushStyle(
        ui.TextStyle(
          color: layer.color,
          fontSize: layer.fontSize * layer.scale,
          fontWeight: layer.fontWeight,
          fontFamily: TextFonts.familyOf(layer.fontFamily),
        ),
      )
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
    final paint = Paint();
    if (layer.gradientColor != null) {
      paint.shader = LinearGradient(
        begin: _gradientBegin(layer.gradientDirection),
        end: _gradientEnd(layer.gradientDirection),
        colors: [layer.color, layer.gradientColor!],
      ).createShader(rect.outerRect);
    } else {
      paint.color = layer.color;
    }
    canvas.drawRRect(rect, paint);
  }

  Alignment _gradientBegin(ColorLayerGradientDirection direction) {
    switch (direction) {
      case ColorLayerGradientDirection.leftToRight:
        return Alignment.centerLeft;
      case ColorLayerGradientDirection.topLeftToBottomRight:
        return Alignment.topLeft;
      case ColorLayerGradientDirection.bottomLeftToTopRight:
        return Alignment.bottomLeft;
      case ColorLayerGradientDirection.topToBottom:
        return Alignment.topCenter;
    }
  }

  Alignment _gradientEnd(ColorLayerGradientDirection direction) {
    switch (direction) {
      case ColorLayerGradientDirection.leftToRight:
        return Alignment.centerRight;
      case ColorLayerGradientDirection.topLeftToBottomRight:
        return Alignment.bottomRight;
      case ColorLayerGradientDirection.bottomLeftToTopRight:
        return Alignment.topRight;
      case ColorLayerGradientDirection.topToBottom:
        return Alignment.bottomCenter;
    }
  }

  void _drawFrame(
    Canvas canvas,
    Size size,
    Rect contentRect,
    double frameOutset,
    FrameConfig frame,
  ) {
    final border = contentRect.left;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(document.cornerRadius + frameOutset),
    );
    final inner = RRect.fromRectAndRadius(
      contentRect,
      Radius.circular(
        (document.cornerRadius - border).clamp(0.0, double.infinity),
      ),
    );

    final path = Path()
      ..addRRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = frame.color);

    if (frame.shaderConfig != null) {
      final program = shaderPrograms[frame.shaderConfig!.shaderAsset];
      if (program != null) {
        final shader = program.fragmentShader();
        shader.setFloat(0, size.width);
        shader.setFloat(1, size.height);
        shader.setFloat(2, tiltState.lightX);
        shader.setFloat(3, tiltState.lightY);
        shader.setFloat(4, tiltState.time);
        if (frame.shaderConfig!.sequinsPalette != -1) {
          shader.setFloat(5, frame.shaderConfig!.sequinsPalette.toDouble());
        }
        canvas.save();
        canvas.clipPath(path);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()
            ..shader = shader
            ..blendMode = frame.shaderConfig!.blendMode,
        );
        canvas.restore();
      }
    }
  }

  void _drawInwardBand(
    Canvas canvas,
    Size size,
    Rect contentRect,
    FrameConfig frame,
  ) {
    final maxInset = (contentRect.shortestSide / 2).clamp(0.0, double.infinity);
    final t = frame.inwardThickness.clamp(0.0, maxInset);
    final border = contentRect.left;

    // The inward band starts from the frame's inner edge and grows inward.
    final outer = RRect.fromRectAndRadius(
      contentRect,
      Radius.circular(
        (document.cornerRadius - border).clamp(0.0, double.infinity),
      ),
    );
    final innerRect = Rect.fromLTWH(
      contentRect.left + t,
      contentRect.top + t,
      (contentRect.width - t * 2).clamp(0.0, contentRect.width),
      (contentRect.height - t * 2).clamp(0.0, contentRect.height),
    );
    final inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(
        (document.cornerRadius - border - t).clamp(0.0, double.infinity),
      ),
    );
    final path = Path()
      ..addRRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = frame.color);

    if (frame.shaderConfig != null) {
      final program = shaderPrograms[frame.shaderConfig!.shaderAsset];
      if (program != null) {
        final shader = program.fragmentShader();
        shader.setFloat(0, size.width);
        shader.setFloat(1, size.height);
        shader.setFloat(2, tiltState.lightX);
        shader.setFloat(3, tiltState.lightY);
        shader.setFloat(4, tiltState.time);
        if (frame.shaderConfig!.sequinsPalette != -1) {
          shader.setFloat(5, frame.shaderConfig!.sequinsPalette.toDouble());
        }
        canvas.save();
        canvas.clipPath(path);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()
            ..shader = shader
            ..blendMode = frame.shaderConfig!.blendMode,
        );
        canvas.restore();
      }
    }
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
