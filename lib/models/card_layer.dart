import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/models/shader_config.dart';

sealed class CardLayer {
  final String id;
  final LayerGroup group;
  final int zIndex;
  final bool visible;
  final double opacity;
  final Offset position;
  final double scale;
  final double rotation;
  final double depthFactor;
  final ShaderConfig? shaderConfig;
  final String name;

  const CardLayer({
    required this.id,
    required this.group,
    required this.zIndex,
    required this.name,
    this.visible = true,
    this.opacity = 1.0,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.depthFactor = 0.0,
    this.shaderConfig,
  });
}

class ImageLayer extends CardLayer {
  final Uint8List? imageBytes;
  final String? assetPath;
  final bool isFoilMask;
  final double cropX;
  final double cropY;

  const ImageLayer({
    required super.id,
    required super.group,
    required super.zIndex,
    required super.name,
    super.visible,
    super.opacity,
    super.position,
    super.scale,
    super.rotation,
    super.depthFactor,
    super.shaderConfig,
    this.imageBytes,
    this.assetPath,
    this.isFoilMask = false,
    this.cropX = 0.0,
    this.cropY = 0.0,
  });

  ImageLayer copyWith({
    bool? visible,
    double? opacity,
    Offset? position,
    double? scale,
    double? rotation,
    double? depthFactor,
    ShaderConfig? shaderConfig,
    bool clearShader = false,
    Uint8List? imageBytes,
    String? assetPath,
    bool? isFoilMask,
    String? name,
    double? cropX,
    double? cropY,
  }) =>
      ImageLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        opacity: opacity ?? this.opacity,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        depthFactor: depthFactor ?? this.depthFactor,
        shaderConfig: clearShader ? null : (shaderConfig ?? this.shaderConfig),
        imageBytes: imageBytes ?? this.imageBytes,
        assetPath: assetPath ?? this.assetPath,
        isFoilMask: isFoilMask ?? this.isFoilMask,
        cropX: cropX ?? this.cropX,
        cropY: cropY ?? this.cropY,
      );
}

class TextLayer extends CardLayer {
  final String text;
  final double fontSize;
  final Color color;
  final TextAlign align;
  final FontWeight fontWeight;

  const TextLayer({
    required super.id,
    required super.group,
    required super.zIndex,
    required super.name,
    super.visible,
    super.opacity,
    super.position,
    super.scale,
    super.rotation,
    super.depthFactor,
    super.shaderConfig,
    required this.text,
    this.fontSize = 24.0,
    this.color = const Color(0xFFFFFFFF),
    this.align = TextAlign.center,
    this.fontWeight = FontWeight.w600,
  });

  TextLayer copyWith({
    bool? visible,
    double? opacity,
    Offset? position,
    double? scale,
    double? rotation,
    double? depthFactor,
    ShaderConfig? shaderConfig,
    bool clearShader = false,
    String? text,
    double? fontSize,
    Color? color,
    TextAlign? align,
    FontWeight? fontWeight,
    String? name,
  }) =>
      TextLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        opacity: opacity ?? this.opacity,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        depthFactor: depthFactor ?? this.depthFactor,
        shaderConfig: clearShader ? null : (shaderConfig ?? this.shaderConfig),
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        color: color ?? this.color,
        align: align ?? this.align,
        fontWeight: fontWeight ?? this.fontWeight,
      );
}

class ColorLayer extends CardLayer {
  final Color color;
  final BorderRadius borderRadius;

  const ColorLayer({
    required super.id,
    required super.group,
    required super.zIndex,
    required super.name,
    super.visible,
    super.opacity,
    super.position,
    super.scale,
    super.rotation,
    super.depthFactor,
    super.shaderConfig,
    required this.color,
    this.borderRadius = BorderRadius.zero,
  });

  ColorLayer copyWith({
    bool? visible,
    double? opacity,
    Offset? position,
    double? scale,
    double? rotation,
    double? depthFactor,
    ShaderConfig? shaderConfig,
    bool clearShader = false,
    Color? color,
    BorderRadius? borderRadius,
    String? name,
  }) =>
      ColorLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        opacity: opacity ?? this.opacity,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        depthFactor: depthFactor ?? this.depthFactor,
        shaderConfig: clearShader ? null : (shaderConfig ?? this.shaderConfig),
        color: color ?? this.color,
        borderRadius: borderRadius ?? this.borderRadius,
      );
}
