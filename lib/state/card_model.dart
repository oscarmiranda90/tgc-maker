import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';

class CardModel extends ChangeNotifier {
  CardDocument _document;
  final Map<String, ui.Image> _images = {};

  CardModel(this._document);

  CardDocument get document => _document;
  Map<String, ui.Image> get images => Map.unmodifiable(_images);

  void addImage(String layerId, ui.Image image) {
    _images[layerId] = image;
    notifyListeners();
  }

  void removeImage(String layerId) {
    _images.remove(layerId);
  }

  void setDocument(CardDocument doc) {
    _document = doc;
    notifyListeners();
  }

  void setSize(CardSize size) {
    _document = _document.copyWith(size: size);
    notifyListeners();
  }

  CardSide get activeSide => _document.activeSide;

  void setActiveSide(CardSide side) {
    if (_document.activeSide == side) return;
    _document = _document.copyWith(activeSide: side);
    notifyListeners();
  }

  /// Flips to the other side of the card.
  void flip() {
    setActiveSide(
      _document.activeSide == CardSide.front ? CardSide.back : CardSide.front,
    );
  }

  void setTitle(String title) {
    _document = _document.copyWith(title: title);
    notifyListeners();
  }

  void addLayer(CardLayer layer) {
    final layers = [..._document.sortedLayers];
    final insertIndex = layers.indexWhere(
      (existing) => existing.group.index > layer.group.index,
    );
    layers.insert(insertIndex == -1 ? layers.length : insertIndex, layer);
    _document = _document.copyWith(layers: _reindexLayers(layers));
    notifyListeners();
  }

  void removeLayer(String id) {
    _images.remove(id);
    _document = _document.copyWith(
      layers: _document.layers.where((l) => l.id != id).toList(),
    );
    notifyListeners();
  }

  /// Duplicates a layer, inserting the copy directly above the original within
  /// the same group. The copy is nudged slightly so it is visible.
  String? duplicateLayer(String id) {
    final source = _document.layers.firstWhere(
      (l) => l.id == id,
      orElse: () => throw StateError('Layer not found: $id'),
    );

    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    const nudge = ui.Offset(12, 12);
    final copy = switch (source) {
      ImageLayer l => l.copyWith(position: l.position + nudge),
      TextLayer l => l.copyWith(position: l.position + nudge),
      ColorLayer l => l.copyWith(position: l.position + nudge),
    };
    final cloned = _withId(copy, newId, '${source.name} copy');

    // Carry over the decoded image so the duplicate renders immediately.
    final sourceImage = _images[id];
    if (sourceImage != null) _images[newId] = sourceImage;

    final layers = [..._document.sortedLayers];
    final index = layers.indexWhere((l) => l.id == id);
    layers.insert(index < 0 ? layers.length : index + 1, cloned);
    _document = _document.copyWith(layers: _reindexLayers(layers));
    notifyListeners();
    return newId;
  }

  CardLayer _withId(CardLayer layer, String id, String name) => switch (layer) {
    ImageLayer l => ImageLayer(
      id: id,
      group: l.group,
      zIndex: l.zIndex,
      name: name,
      visible: l.visible,
      opacity: l.opacity,
      position: l.position,
      scale: l.scale,
      rotation: l.rotation,
      depthFactor: l.depthFactor,
      shaderConfig: l.shaderConfig,
      imageBytes: l.imageBytes,
      assetPath: l.assetPath,
      isFoilMask: l.isFoilMask,
      cropX: l.cropX,
      cropY: l.cropY,
    ),
    TextLayer l => TextLayer(
      id: id,
      group: l.group,
      zIndex: l.zIndex,
      name: name,
      visible: l.visible,
      opacity: l.opacity,
      position: l.position,
      scale: l.scale,
      rotation: l.rotation,
      depthFactor: l.depthFactor,
      shaderConfig: l.shaderConfig,
      text: l.text,
      fontSize: l.fontSize,
      color: l.color,
      align: l.align,
      fontWeight: l.fontWeight,
      fontFamily: l.fontFamily,
    ),
    ColorLayer l => ColorLayer(
      id: id,
      group: l.group,
      zIndex: l.zIndex,
      name: name,
      visible: l.visible,
      opacity: l.opacity,
      position: l.position,
      scale: l.scale,
      rotation: l.rotation,
      depthFactor: l.depthFactor,
      shaderConfig: l.shaderConfig,
      color: l.color,
      gradientColor: l.gradientColor,
      gradientDirection: l.gradientDirection,
      borderRadius: l.borderRadius,
    ),
  };

  void updateLayer(String id, CardLayer updated) {
    _document = _document.copyWith(
      layers: _document.layers.map((l) => l.id == id ? updated : l).toList(),
    );
    notifyListeners();
  }

  Future<void> replaceImageLayerSource(String id, Uint8List imageBytes) async {
    final layer = _document.layers.firstWhere((entry) => entry.id == id);
    if (layer is! ImageLayer) return;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    _images[id] = frame.image;
    _document = _document.copyWith(
      layers: _document.layers.map((entry) {
        if (entry.id != id) return entry;
        return layer.copyWith(imageBytes: imageBytes, clearAssetPath: true);
      }).toList(),
    );
    notifyListeners();
  }

  void reorderLayerById(
    String movedId,
    LayerGroup destinationGroup,
    String? beforeId,
  ) {
    final layers = [..._document.sortedLayers];
    final item = layers.firstWhere((l) => l.id == movedId);
    layers.removeWhere((layer) => layer.id == movedId);
    final moved = _copyLayer(item, group: destinationGroup);
    if (beforeId == null) {
      layers.add(moved);
    } else {
      final targetIndex = layers.indexWhere((l) => l.id == beforeId);
      layers.insert(targetIndex < 0 ? layers.length : targetIndex, moved);
    }
    _document = _document.copyWith(layers: _reindexLayers(layers));
    notifyListeners();
  }

  List<CardLayer> _reindexLayers(List<CardLayer> layers) => [
    for (var i = 0; i < layers.length; i++) _copyLayer(layers[i], zIndex: i),
  ];

  CardLayer _copyLayer(CardLayer layer, {LayerGroup? group, int? zIndex}) =>
      switch (layer) {
        ImageLayer image => image.copyWith(group: group, zIndex: zIndex),
        TextLayer text => text.copyWith(group: group, zIndex: zIndex),
        ColorLayer color => color.copyWith(group: group, zIndex: zIndex),
      };

  void setFrame(FrameConfig? config) {
    _document = config != null
        ? _document.copyWith(frameConfig: config)
        : _document.copyWith(clearFrame: true);
    notifyListeners();
  }

  void toggleFrameVisibility() {
    final frame = _document.frameConfig ?? const FrameConfig();
    _document = _document.copyWith(
      frameConfig: frame.copyWith(visible: !frame.visible),
    );
    notifyListeners();
  }

  void renameLayer(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final layer = _document.layers.firstWhere((l) => l.id == id);
    final CardLayer updated = switch (layer) {
      ImageLayer l => l.copyWith(name: trimmed),
      TextLayer l => l.copyWith(name: trimmed),
      ColorLayer l => l.copyWith(name: trimmed),
    };
    updateLayer(id, updated);
  }

  void toggleLayerVisibility(String id) {
    final layer = _document.layers.firstWhere((l) => l.id == id);
    CardLayer updated;
    if (layer is ImageLayer) {
      updated = layer.copyWith(visible: !layer.visible);
    } else if (layer is TextLayer) {
      updated = layer.copyWith(visible: !layer.visible);
    } else {
      updated = (layer as ColorLayer).copyWith(visible: !layer.visible);
    }
    updateLayer(id, updated);
  }
}
