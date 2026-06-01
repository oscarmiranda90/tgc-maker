import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/models/shader_config.dart';

class DecodedCardDocument {
  final CardDocument document;
  final Map<String, ui.Image> images;

  const DecodedCardDocument({required this.document, required this.images});
}

/// Typed error raised when a card JSON payload cannot be safely decoded.
///
/// Consumers can catch this explicitly instead of relying on raw
/// [FormatException] / [TypeError] propagating from the codec internals.
class CardCodecException implements Exception {
  final String message;
  final String? field;

  const CardCodecException(this.message, {this.field});

  @override
  String toString() => field == null
      ? 'CardCodecException: $message'
      : 'CardCodecException($field): $message';
}

/// Outcome of attempting to migrate a payload into the current schema.
class CardMigrationResult {
  final DecodedCardDocument decoded;
  final String? migratedFromVersion;

  const CardMigrationResult({required this.decoded, this.migratedFromVersion});
}

/// Stable JSON contract for card documents used across app storage and
/// package-consumer integrations.
class CardDocumentCodec {
  static const String currentSchemaVersion = '1.0.0';
  static const String legacyVersion = '0.x';

  /// Public entry point: decode a payload from any supported schema
  /// version, migrating it forward when required.
  ///
  /// Use this from package-consumer code instead of [fromJson] when the
  /// payload may have been written by an older release.
  static Future<CardMigrationResult> migrateAndDecode(
    Map<String, dynamic> json,
  ) async {
    final rawVersion = json['schemaVersion'];
    if (rawVersion == null) {
      final decoded = await fromJson(json);
      return CardMigrationResult(
        decoded: decoded,
        migratedFromVersion: legacyVersion,
      );
    }
    if (rawVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported schemaVersion "$rawVersion". '
        'Supported: $currentSchemaVersion or legacy ($legacyVersion).',
      );
    }
    final decoded = await fromJson(json);
    return CardMigrationResult(decoded: decoded);
  }

  static Future<Map<String, dynamic>> toJson(
    CardDocument doc,
    Map<String, ui.Image> images,
  ) async {
    return {
      'schemaVersion': currentSchemaVersion,
      'id': doc.id,
      'title': doc.title,
      'size': _sizeToJson(doc.size),
      'cornerRadius': doc.cornerRadius,
      'frameWindowInset': doc.frameWindowInset,
      'frameWindowRadius': doc.frameWindowRadius,
      'activeSide': doc.activeSide.name,
      'front': await _faceToJson(doc.front, images),
      'back': await _faceToJson(doc.back, images),
    };
  }

  static Future<DecodedCardDocument> fromJson(Map<String, dynamic> json) async {
    final size = _sizeFromJson(json['size'] as Map<String, dynamic>);
    final images = <String, ui.Image>{};

    final CardFace front;
    final CardFace back;
    if (json['front'] != null || json['back'] != null) {
      final (f, fImages) = await _faceFromJson(_asMap(json['front']));
      final (b, bImages) = await _faceFromJson(_asMap(json['back']));
      front = f;
      back = b;
      images
        ..addAll(fImages)
        ..addAll(bImages);
    } else {
      final (f, fImages) = await _faceFromJson(json);
      front = f;
      back = CardFace.empty;
      images.addAll(fImages);
    }

    final activeSide = CardSide.values.firstWhere(
      (s) => s.name == json['activeSide'],
      orElse: () => CardSide.front,
    );

    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const CardCodecException('Missing or empty id', field: 'id');
    }
    final title = json['title'];
    if (title is! String) {
      throw const CardCodecException('Missing title', field: 'title');
    }
    final cornerRadius = _asDouble(json['cornerRadius'], 'cornerRadius');
    final frameWindowInset = _asDouble(
      json['frameWindowInset'],
      'frameWindowInset',
    );
    final frameWindowRadius = _asDouble(
      json['frameWindowRadius'],
      'frameWindowRadius',
    );

    final doc = CardDocument(
      id: id,
      title: title,
      size: size,
      front: front,
      back: back,
      activeSide: activeSide,
      cornerRadius: cornerRadius,
      frameWindowInset: frameWindowInset,
      frameWindowRadius: frameWindowRadius,
    );

    return DecodedCardDocument(document: doc, images: images);
  }

  static Future<Map<String, dynamic>> _faceToJson(
    CardFace face,
    Map<String, ui.Image> images,
  ) async {
    final layersJson = <Map<String, dynamic>>[];
    for (final layer in face.layers) {
      layersJson.add(await _layerToJson(layer, images));
    }
    return {
      'layers': layersJson,
      if (face.frameConfig != null)
        'frameConfig': _frameToJson(face.frameConfig!),
    };
  }

  static Future<(CardFace, Map<String, ui.Image>)> _faceFromJson(
    Map<String, dynamic> json,
  ) async {
    final images = <String, ui.Image>{};
    final layers = <CardLayer>[];
    for (final layerJson in (json['layers'] as List? ?? const [])) {
      final (layer, image) = await _layerFromJson(
        layerJson as Map<String, dynamic>,
      );
      layers.add(layer);
      if (image != null) images[layer.id] = image;
    }

    return (
      CardFace(
        layers: layers,
        frameConfig: json['frameConfig'] != null
            ? _frameFromJson(json['frameConfig'] as Map<String, dynamic>)
            : null,
      ),
      images,
    );
  }

  static Future<Map<String, dynamic>> _layerToJson(
    CardLayer layer,
    Map<String, ui.Image> images,
  ) async {
    final base = {
      'type': layer.runtimeType.toString(),
      'id': layer.id,
      'group': layer.group.name,
      'zIndex': layer.zIndex,
      'name': layer.name,
      'visible': layer.visible,
      'opacity': layer.opacity,
      'posX': layer.position.dx,
      'posY': layer.position.dy,
      'scale': layer.scale,
      'rotation': layer.rotation,
      'depthFactor': layer.depthFactor,
      if (layer.shaderConfig != null)
        'shaderConfig': _shaderToJson(layer.shaderConfig!),
    };

    switch (layer) {
      case ImageLayer l:
        if (l.assetPath != null) {
          base['assetPath'] = l.assetPath!;
        } else if (l.imageBytes != null) {
          base['imageBytes'] = base64Encode(l.imageBytes!);
        }
        base['isFoilMask'] = l.isFoilMask;
        base['cropX'] = l.cropX;
        base['cropY'] = l.cropY;
      case TextLayer l:
        base['text'] = l.text;
        base['fontSize'] = l.fontSize;
        base['color'] = l.color.toARGB32();
        base['align'] = l.align.name;
        base['fontWeight'] = l.fontWeight.value;
        base['fontFamily'] = l.fontFamily;
      case ColorLayer l:
        base['color'] = l.color.toARGB32();
        if (l.gradientColor != null) {
          base['gradientColor'] = l.gradientColor!.toARGB32();
          base['gradientDirection'] = l.gradientDirection.name;
        }
    }

    return base;
  }

  static Future<(CardLayer, ui.Image?)> _layerFromJson(
    Map<String, dynamic> json,
  ) async {
    final id = json['id'] as String;
    final group = LayerGroup.values.byName(json['group'] as String);
    final zIndex = json['zIndex'] as int;
    final name = json['name'] as String;
    final visible = json['visible'] as bool;
    final opacity = (json['opacity'] as num).toDouble();
    final posX = (json['posX'] as num).toDouble();
    final posY = (json['posY'] as num).toDouble();
    final scale = (json['scale'] as num).toDouble();
    final rotation = (json['rotation'] as num).toDouble();
    final depthFactor = (json['depthFactor'] as num).toDouble();
    final shaderConfig = json['shaderConfig'] != null
        ? _shaderFromJson(json['shaderConfig'] as Map<String, dynamic>)
        : null;

    final type = json['type'] as String;

    if (type == 'ImageLayer') {
      ui.Image? image;
      Uint8List? bytes;
      String? assetPath;

      if (json['assetPath'] != null) {
        assetPath = json['assetPath'] as String;
        try {
          final data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          image = (await codec.getNextFrame()).image;
        } catch (_) {}
      } else if (json['imageBytes'] != null) {
        bytes = base64Decode(json['imageBytes'] as String);
        final codec = await ui.instantiateImageCodec(bytes);
        image = (await codec.getNextFrame()).image;
      }

      return (
        ImageLayer(
          id: id,
          group: group,
          zIndex: zIndex,
          name: name,
          visible: visible,
          opacity: opacity,
          position: Offset(posX, posY),
          scale: scale,
          rotation: rotation,
          depthFactor: depthFactor,
          shaderConfig: shaderConfig,
          imageBytes: bytes,
          assetPath: assetPath,
          isFoilMask: json['isFoilMask'] as bool? ?? false,
          cropX: (json['cropX'] as num?)?.toDouble() ?? 0.0,
          cropY: (json['cropY'] as num?)?.toDouble() ?? 0.0,
        ),
        image,
      );
    }

    if (type == 'TextLayer') {
      return (
        TextLayer(
          id: id,
          group: group,
          zIndex: zIndex,
          name: name,
          visible: visible,
          opacity: opacity,
          position: Offset(posX, posY),
          scale: scale,
          rotation: rotation,
          depthFactor: depthFactor,
          shaderConfig: shaderConfig,
          text: json['text'] as String,
          fontSize: (json['fontSize'] as num).toDouble(),
          color: Color(json['color'] as int),
          align: TextAlign.values.byName(json['align'] as String),
          fontWeight: FontWeight.values.firstWhere(
            (w) => w.value == json['fontWeight'] as int,
            orElse: () => FontWeight.w600,
          ),
          fontFamily: json['fontFamily'] as String? ?? 'Roboto',
        ),
        null,
      );
    }

    return (
      ColorLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: name,
        visible: visible,
        opacity: opacity,
        position: Offset(posX, posY),
        scale: scale,
        rotation: rotation,
        depthFactor: depthFactor,
        shaderConfig: shaderConfig,
        color: Color(json['color'] as int),
        gradientColor: json['gradientColor'] != null
            ? Color(json['gradientColor'] as int)
            : null,
        gradientDirection: json['gradientDirection'] != null
            ? ColorLayerGradientDirection.values.byName(
                json['gradientDirection'] as String,
              )
            : ColorLayerGradientDirection.topToBottom,
      ),
      null,
    );
  }

  static Map<String, dynamic> _sizeToJson(CardSize size) => {
    'preset': size.preset.name,
    'widthPx': size.widthPx,
    'heightPx': size.heightPx,
    'label': size.label,
  };

  static CardSize _sizeFromJson(Map<String, dynamic> json) {
    final presetRaw = json['preset'];
    if (presetRaw is! String) {
      throw const CardCodecException(
        'Missing size preset',
        field: 'size.preset',
      );
    }
    final preset = CardSizePreset.values.firstWhere(
      (p) => p.name == presetRaw,
      orElse: () => throw CardCodecException(
        'Unknown size preset: $presetRaw',
        field: 'size.preset',
      ),
    );
    return switch (preset) {
      CardSizePreset.standard => CardSize.standard,
      CardSizePreset.japanese => CardSize.japanese,
      CardSizePreset.custom => CardSize.custom(
        (json['widthPx'] as num).toDouble(),
        (json['heightPx'] as num).toDouble(),
      ),
    };
  }

  static double _asDouble(Object? value, String field) {
    if (value is num) return value.toDouble();
    throw CardCodecException('Expected numeric value', field: field);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value == null) return const {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw CardCodecException('Expected object value', field: 'face');
  }

  static Map<String, dynamic> _shaderToJson(ShaderConfig shader) => {
    'shaderAsset': shader.shaderAsset,
    'opacity': shader.opacity,
    'blendMode': shader.blendMode.index,
    'sequinsPalette': shader.sequinsPalette,
  };

  static ShaderConfig _shaderFromJson(Map<String, dynamic> json) =>
      ShaderConfig(
        shaderAsset: json['shaderAsset'] as String,
        opacity: (json['opacity'] as num).toDouble(),
        blendMode: BlendMode.values[json['blendMode'] as int],
        sequinsPalette: json['sequinsPalette'] as int,
      );

  static Map<String, dynamic> _frameToJson(FrameConfig frame) => {
    'visible': frame.visible,
    'thickness': frame.thickness,
    'color': frame.color.toARGB32(),
    if (frame.shaderConfig != null)
      'shaderConfig': _shaderToJson(frame.shaderConfig!),
    'inwardThickness': frame.inwardThickness,
  };

  static FrameConfig _frameFromJson(Map<String, dynamic> json) => FrameConfig(
    visible: json['visible'] as bool,
    thickness: (json['thickness'] as num).toDouble(),
    color: Color(json['color'] as int),
    shaderConfig: json['shaderConfig'] != null
        ? _shaderFromJson(json['shaderConfig'] as Map<String, dynamic>)
        : null,
    inwardThickness: (json['inwardThickness'] as num?)?.toDouble() ?? 0.0,
  );
}
