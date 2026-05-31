import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tgc_maker/engine/card_painter.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_layer.dart';

class LayerGeometry {
  static int? hitTestInteractiveLayer(
    CardDocument document,
    Size size,
    Offset point,
    Map<String, ui.Image> images,
  ) {
    final layers = document.sortedLayers;
    for (var i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.visible || !_isInteractive(layer)) continue;
      final bounds = boundsForLayer(document, layer, size, images);
      if (bounds != null && bounds.contains(point)) {
        return i;
      }
    }
    return null;
  }

  static Rect? boundsForSelectedLayer(
    CardDocument document,
    Size size,
    int? selectedLayerIndex,
    Map<String, ui.Image> images,
  ) {
    if (selectedLayerIndex == null) return null;
    final layers = document.sortedLayers;
    if (selectedLayerIndex < 0 || selectedLayerIndex >= layers.length) {
      return null;
    }
    final layer = layers[selectedLayerIndex];
    if (!layer.visible || !_isInteractive(layer)) return null;
    return boundsForLayer(document, layer, size, images);
  }

  static Rect? boundsForLayer(
    CardDocument document,
    CardLayer layer,
    Size size,
    Map<String, ui.Image> images,
  ) {
    final contentRect = _contentRect(document, size);

    switch (layer) {
      case ImageLayer imageLayer:
        return _imageBounds(imageLayer, contentRect, images);
      case TextLayer textLayer:
        return _textBounds(textLayer, contentRect);
      default:
        return null;
    }
  }

  static Rect _contentRect(CardDocument document, Size size) {
    final border = CardPainter.frameBorderForDocument(document);
    return Rect.fromLTWH(
      border,
      border,
      (size.width - border * 2).clamp(0.0, size.width),
      (size.height - border * 2).clamp(0.0, size.height),
    );
  }

  static bool _isInteractive(CardLayer layer) =>
      layer is ImageLayer || layer is TextLayer;

  static Rect? _imageBounds(
    ImageLayer layer,
    Rect contentRect,
    Map<String, ui.Image> images,
  ) {
    final image = images[layer.id] ?? images[layer.assetPath ?? ''];
    if (image == null) return null;

    final size = contentRect.size;

    final scaleX = size.width * layer.scale / image.width;
    final scaleY = size.height * layer.scale / image.height;
    final fittedScale = scaleX > scaleY ? scaleX : scaleY;
    final drawW = image.width * fittedScale;
    final drawH = image.height * fittedScale;
    final cropX = layer.cropX.clamp(0.0, 0.95);
    final cropY = layer.cropY.clamp(0.0, 0.95);
    final visibleW = drawW * (1 - cropX);
    final visibleH = drawH * (1 - cropY);
    final dx = (size.width - drawW) / 2 + layer.position.dx;
    final dy = (size.height - drawH) / 2 + layer.position.dy;

    return Rect.fromLTWH(
      contentRect.left + dx + (drawW - visibleW) / 2,
      contentRect.top + dy + (drawH - visibleH) / 2,
      visibleW,
      visibleH,
    );
  }

  static Rect _textBounds(TextLayer layer, Rect contentRect) {
    final size = contentRect.size;
    final style = ui.ParagraphStyle(textAlign: layer.align, maxLines: 5);
    final builder = ui.ParagraphBuilder(style)
      ..pushStyle(
        ui.TextStyle(
          color: layer.color,
          fontSize: layer.fontSize * layer.scale,
          fontWeight: layer.fontWeight,
        ),
      )
      ..addText(layer.text);

    const horizontalInset = 16.0;
    final availableWidth = size.width - horizontalInset * 2;
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: availableWidth));
    final textWidth = paragraph.longestLine.clamp(0.0, availableWidth);
    final left = switch (layer.align) {
      TextAlign.right || TextAlign.end =>
        horizontalInset + layer.position.dx + (availableWidth - textWidth),
      TextAlign.center =>
        horizontalInset + layer.position.dx + (availableWidth - textWidth) / 2,
      _ => horizontalInset + layer.position.dx,
    };
    final top = (size.height - paragraph.height) / 2 + layer.position.dy;

    return Rect.fromLTWH(
      contentRect.left + left,
      contentRect.top + top,
      textWidth,
      paragraph.height,
    );
  }
}
