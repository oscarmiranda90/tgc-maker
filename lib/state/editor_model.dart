import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:tgc_maker/engine/shader_registry.dart';

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
        _shaders[asset] = await ui.FragmentProgram.fromAsset(asset);
      } catch (e) {
        debugPrint('Shader load error [$asset]: $e');
      }
    }
    _shadersLoaded = true;
    notifyListeners();
  }

  ui.FragmentShader? shaderFor(String asset) =>
      _shaders[asset]?.fragmentShader();
}
