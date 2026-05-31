import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/models/shader_config.dart';

class SavedCard {
  final CardDocument document;
  final Map<String, ui.Image> images;

  const SavedCard({required this.document, required this.images});
}

class CardStore {
  static Future<Directory> _cardsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/tgc_cards');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _cardFile(String id) async {
    final dir = await _cardsDir();
    return File('${dir.path}/$id.json');
  }

  // ── List all saved card IDs + titles ─────────────────────────────
  static Future<List<({String id, String title, DateTime savedAt})>>
  listCards() async {
    final dir = await _cardsDir();
    final files = await dir
        .list()
        .where((e) => e.path.endsWith('.json'))
        .toList();

    final result = <({String id, String title, DateTime savedAt})>[];
    for (final f in files) {
      try {
        final raw = await File(f.path).readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        result.add((
          id: json['id'] as String,
          title: json['title'] as String,
          savedAt: DateTime.parse(json['savedAt'] as String),
        ));
      } catch (_) {}
    }
    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }

  // ── Save ─────────────────────────────────────────────────────────
  static Future<void> save(
    CardDocument doc,
    Map<String, ui.Image> images,
  ) async {
    final file = await _cardFile(doc.id);
    final json = await _documentToJson(doc, images);
    json['savedAt'] = DateTime.now().toIso8601String();
    await file.writeAsString(jsonEncode(json));
  }

  // ── Load ─────────────────────────────────────────────────────────
  static Future<SavedCard> load(String id) async {
    final file = await _cardFile(id);
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _documentFromJson(json);
  }

  // ── Delete ───────────────────────────────────────────────────────
  static Future<void> delete(String id) async {
    final file = await _cardFile(id);
    if (await file.exists()) await file.delete();
  }

  // ── Serialization ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _documentToJson(
    CardDocument doc,
    Map<String, ui.Image> images,
  ) async {
    final layersJson = <Map<String, dynamic>>[];
    for (final layer in doc.layers) {
      layersJson.add(await _layerToJson(layer, images));
    }
    return {
      'id': doc.id,
      'title': doc.title,
      'size': _sizeToJson(doc.size),
      'cornerRadius': doc.cornerRadius,
      'frameWindowInset': doc.frameWindowInset,
      'frameWindowRadius': doc.frameWindowRadius,
      'layers': layersJson,
      if (doc.frameConfig != null)
        'frameConfig': _frameToJson(doc.frameConfig!),
    };
  }

  static Future<SavedCard> _documentFromJson(Map<String, dynamic> j) async {
    final size = _sizeFromJson(j['size'] as Map<String, dynamic>);
    final images = <String, ui.Image>{};
    final layers = <CardLayer>[];

    for (final lj in (j['layers'] as List)) {
      final (layer, img) = await _layerFromJson(lj as Map<String, dynamic>);
      layers.add(layer);
      if (img != null) images[layer.id] = img;
    }

    final doc = CardDocument(
      id: j['id'] as String,
      title: j['title'] as String,
      size: size,
      layers: layers,
      cornerRadius: (j['cornerRadius'] as num).toDouble(),
      frameWindowInset: (j['frameWindowInset'] as num).toDouble(),
      frameWindowRadius: (j['frameWindowRadius'] as num).toDouble(),
      frameConfig: j['frameConfig'] != null
          ? _frameFromJson(j['frameConfig'] as Map<String, dynamic>)
          : null,
    );
    return SavedCard(document: doc, images: images);
  }

  // ── Layer ────────────────────────────────────────────────────────

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
    Map<String, dynamic> j,
  ) async {
    final id = j['id'] as String;
    final group = LayerGroup.values.byName(j['group'] as String);
    final zIndex = j['zIndex'] as int;
    final name = j['name'] as String;
    final visible = j['visible'] as bool;
    final opacity = (j['opacity'] as num).toDouble();
    final posX = (j['posX'] as num).toDouble();
    final posY = (j['posY'] as num).toDouble();
    final scale = (j['scale'] as num).toDouble();
    final rotation = (j['rotation'] as num).toDouble();
    final depthFactor = (j['depthFactor'] as num).toDouble();
    final shaderConfig = j['shaderConfig'] != null
        ? _shaderFromJson(j['shaderConfig'] as Map<String, dynamic>)
        : null;

    final type = j['type'] as String;

    if (type == 'ImageLayer') {
      ui.Image? img;
      Uint8List? bytes;
      String? assetPath;

      if (j['assetPath'] != null) {
        assetPath = j['assetPath'] as String;
        try {
          final data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          img = (await codec.getNextFrame()).image;
        } catch (_) {}
      } else if (j['imageBytes'] != null) {
        bytes = base64Decode(j['imageBytes'] as String);
        final codec = await ui.instantiateImageCodec(bytes);
        img = (await codec.getNextFrame()).image;
      }

      final layer = ImageLayer(
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
        isFoilMask: j['isFoilMask'] as bool? ?? false,
        cropX: (j['cropX'] as num?)?.toDouble() ?? 0.0,
        cropY: (j['cropY'] as num?)?.toDouble() ?? 0.0,
      );
      return (layer, img);
    }

    if (type == 'TextLayer') {
      final layer = TextLayer(
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
        text: j['text'] as String,
        fontSize: (j['fontSize'] as num).toDouble(),
        color: Color(j['color'] as int),
        align: TextAlign.values.byName(j['align'] as String),
        fontWeight: FontWeight.values.firstWhere(
          (w) => w.value == j['fontWeight'] as int,
          orElse: () => FontWeight.w600,
        ),
        fontFamily: j['fontFamily'] as String? ?? 'Roboto',
      );
      return (layer, null);
    }

    // ColorLayer
    final layer = ColorLayer(
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
      color: Color(j['color'] as int),
      gradientColor: j['gradientColor'] != null
          ? Color(j['gradientColor'] as int)
          : null,
      gradientDirection: j['gradientDirection'] != null
          ? ColorLayerGradientDirection.values.byName(
              j['gradientDirection'] as String,
            )
          : ColorLayerGradientDirection.topToBottom,
    );
    return (layer, null);
  }

  // ── Size ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _sizeToJson(CardSize size) => {
    'preset': size.preset.name,
    'widthPx': size.widthPx,
    'heightPx': size.heightPx,
    'label': size.label,
  };

  static CardSize _sizeFromJson(Map<String, dynamic> j) {
    final preset = CardSizePreset.values.byName(j['preset'] as String);
    return switch (preset) {
      CardSizePreset.standard => CardSize.standard,
      CardSizePreset.japanese => CardSize.japanese,
      CardSizePreset.custom => CardSize.custom(
        (j['widthPx'] as num).toDouble(),
        (j['heightPx'] as num).toDouble(),
      ),
    };
  }

  // ── Shader ───────────────────────────────────────────────────────

  static Map<String, dynamic> _shaderToJson(ShaderConfig s) => {
    'shaderAsset': s.shaderAsset,
    'opacity': s.opacity,
    'blendMode': s.blendMode.index,
    'sequinsPalette': s.sequinsPalette,
  };

  static ShaderConfig _shaderFromJson(Map<String, dynamic> j) => ShaderConfig(
    shaderAsset: j['shaderAsset'] as String,
    opacity: (j['opacity'] as num).toDouble(),
    blendMode: BlendMode.values[j['blendMode'] as int],
    sequinsPalette: j['sequinsPalette'] as int,
  );

  // ── Frame ────────────────────────────────────────────────────────

  static Map<String, dynamic> _frameToJson(FrameConfig f) => {
    'visible': f.visible,
    'thickness': f.thickness,
    'color': f.color.toARGB32(),
    if (f.shaderConfig != null) 'shaderConfig': _shaderToJson(f.shaderConfig!),
    'inwardThickness': f.inwardThickness,
  };

  static FrameConfig _frameFromJson(Map<String, dynamic> j) => FrameConfig(
    visible: j['visible'] as bool,
    thickness: (j['thickness'] as num).toDouble(),
    color: Color(j['color'] as int),
    shaderConfig: j['shaderConfig'] != null
        ? _shaderFromJson(j['shaderConfig'] as Map<String, dynamic>)
        : null,
    inwardThickness: (j['inwardThickness'] as num?)?.toDouble() ?? 0.0,
  );
}
