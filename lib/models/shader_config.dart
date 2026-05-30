import 'package:flutter/material.dart';

class ShaderConfig {
  final String shaderAsset;
  final double opacity;
  final BlendMode blendMode;
  final int sequinsPalette;

  const ShaderConfig({
    required this.shaderAsset,
    this.opacity = 0.85,
    this.blendMode = BlendMode.screen,
    this.sequinsPalette = -1,
  });

  ShaderConfig copyWith({
    String? shaderAsset,
    double? opacity,
    BlendMode? blendMode,
    int? sequinsPalette,
  }) =>
      ShaderConfig(
        shaderAsset: shaderAsset ?? this.shaderAsset,
        opacity: opacity ?? this.opacity,
        blendMode: blendMode ?? this.blendMode,
        sequinsPalette: sequinsPalette ?? this.sequinsPalette,
      );

  @override
  bool operator ==(Object other) =>
      other is ShaderConfig &&
      shaderAsset == other.shaderAsset &&
      opacity == other.opacity &&
      blendMode == other.blendMode &&
      sequinsPalette == other.sequinsPalette;

  @override
  int get hashCode => Object.hash(shaderAsset, opacity, blendMode, sequinsPalette);
}
