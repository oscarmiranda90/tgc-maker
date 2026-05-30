import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_layer.dart';

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

  void setTitle(String title) {
    _document = _document.copyWith(title: title);
    notifyListeners();
  }

  void addLayer(CardLayer layer) {
    _document = _document.copyWith(layers: [..._document.layers, layer]);
    notifyListeners();
  }

  void removeLayer(String id) {
    _images.remove(id);
    _document = _document.copyWith(
      layers: _document.layers.where((l) => l.id != id).toList(),
    );
    notifyListeners();
  }

  void updateLayer(String id, CardLayer updated) {
    _document = _document.copyWith(
      layers: _document.layers.map((l) => l.id == id ? updated : l).toList(),
    );
    notifyListeners();
  }

  void reorderLayer(int oldIndex, int newIndex) {
    final layers = [..._document.layers];
    final item = layers.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    layers.insert(insertAt, item);
    // Reassign zIndex to match new order
    final reindexed = <CardLayer>[];
    for (var i = 0; i < layers.length; i++) {
      final l = layers[i];
      if (l is ImageLayer) {
        reindexed.add(l.copyWith());
      } else if (l is TextLayer) {
        reindexed.add(l.copyWith());
      } else if (l is ColorLayer) {
        reindexed.add(l.copyWith());
      }
    }
    _document = _document.copyWith(layers: reindexed);
    notifyListeners();
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
