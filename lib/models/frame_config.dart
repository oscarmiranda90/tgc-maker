import 'package:flutter/material.dart';
import 'package:tgc_maker/models/shader_config.dart';

class FrameConfig {
  final bool visible;
  final double thickness;
  final Color color;
  final ShaderConfig? shaderConfig;
  /// Extra band drawn inward from the card edge, on top of the content.
  /// 0.0 = no inward band. Measured in logical pixels.
  final double inwardThickness;

  const FrameConfig({
    this.visible = true,
    this.thickness = 8.0,
    this.color = const Color(0xFF000000),
    this.shaderConfig,
    this.inwardThickness = 0.0,
  });

  FrameConfig copyWith({
    bool? visible,
    double? thickness,
    Color? color,
    ShaderConfig? shaderConfig,
    bool clearShader = false,
    double? inwardThickness,
  }) =>
      FrameConfig(
        visible: visible ?? this.visible,
        thickness: thickness ?? this.thickness,
        color: color ?? this.color,
        shaderConfig: clearShader ? null : (shaderConfig ?? this.shaderConfig),
        inwardThickness: inwardThickness ?? this.inwardThickness,
      );
}
