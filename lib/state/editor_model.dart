import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:tgc_maker/engine/shader_registry.dart';
import 'package:tgc_maker/engine/text_fonts.dart';

enum EditorTool { none, move, addImage, addText, addColor }

class EditorModel extends ChangeNotifier {
  int? _selectedLayerIndex;
  EditorTool _activeTool = EditorTool.none;
  final Map<String, ui.FragmentProgram> _shaders = {};
  bool _shadersLoaded = false;

  int? get selectedLayerIndex => _selectedLayerIndex;
  EditorTool get activeTool => _activeTool;
  Map<String, ui.FragmentProgram> get shaders => _shaders;
  bool get shadersLoaded => _shadersLoaded;

  void selectLayer(int? index) {
    _selectedLayerIndex = index;
    notifyListeners();
  }

  void setTool(EditorTool tool) {
    _activeTool = tool;
    notifyListeners();
  }

  Future<void> loadShaders() async {
    for (final asset in TgcShaders.all) {
      try {
        _shaders[asset] = await _loadShaderProgram(asset);
      } catch (e) {
        debugPrint('Shader load error [$asset]: $e');
      }
    }
    _shadersLoaded = true;
    notifyListeners();
  }

  ui.FragmentShader? shaderFor(String asset) =>
      _shaders[asset]?.fragmentShader();

  Future<ui.FragmentProgram> _loadShaderProgram(String asset) async {
    try {
      return await ui.FragmentProgram.fromAsset(asset);
    } catch (e) {
      if (!_isAssetLookupFailure(e)) {
        rethrow;
      }
      // When consumed as a dependency, package assets are prefixed.
      return ui.FragmentProgram.fromAsset('packages/tgc_maker/$asset');
    }
  }

  bool _isAssetLookupFailure(Object error) {
    final message = error.toString();
    return message.contains('Asset') && message.contains('not found');
  }

  Future<void> loadFonts() async {
    try {
      await TextFonts.preloadAll();
    } catch (e) {
      debugPrint('Font preload error: $e');
    }
    // Repaint so the canvas renders with the now-loaded fonts.
    notifyListeners();
  }
}
