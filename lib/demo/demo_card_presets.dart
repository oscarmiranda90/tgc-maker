import 'package:flutter/material.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/engine/shader_registry.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/models/shader_config.dart';

class DemoCardPresets {
  static List<CardDocument> get all => [holographic, sparkle, sequins];

  static CardDocument get holographic => CardDocument(
        id: 'demo_holo',
        title: 'Holographic',
        size: CardSize.standard,
        front: CardFace(layers: [
          ColorLayer(
            id: 'demo_holo_bg',
            group: LayerGroup.background,
            zIndex: 0,
            name: 'Background',
            color: const Color(0xFF0A0A1E),
            depthFactor: 1.0,
            shaderConfig: const ShaderConfig(
              shaderAsset: TgcShaders.holographic,
              opacity: 0.9,
            ),
          ),
          TextLayer(
            id: 'demo_holo_title',
            group: LayerGroup.layout,
            zIndex: 10,
            name: 'Card Name',
            text: 'HOLOGRAPHIC',
            fontSize: 32,
            color: Colors.white,
            depthFactor: 0.0,
          ),
          TextLayer(
            id: 'demo_holo_sub',
            group: LayerGroup.layout,
            zIndex: 11,
            name: 'Subtitle',
            text: 'TGC MAKER ENGINE',
            fontSize: 14,
            color: Colors.white54,
            position: const Offset(0, 60),
            depthFactor: 0.0,
          ),
        ]),
      );

  static CardDocument get sparkle => CardDocument(
        id: 'demo_sparkle',
        title: 'Sparkle',
        size: CardSize.standard,
        front: CardFace(layers: [
          ColorLayer(
            id: 'demo_sparkle_bg',
            group: LayerGroup.background,
            zIndex: 0,
            name: 'Background',
            color: const Color(0xFF060612),
            depthFactor: 1.0,
            shaderConfig: const ShaderConfig(
              shaderAsset: TgcShaders.sparkle,
              opacity: 0.95,
            ),
          ),
          TextLayer(
            id: 'demo_sparkle_title',
            group: LayerGroup.layout,
            zIndex: 10,
            name: 'Card Name',
            text: 'SPARKLE',
            fontSize: 36,
            color: Colors.white,
            depthFactor: 0.2,
          ),
        ]),
      );

  static CardDocument get sequins => CardDocument(
        id: 'demo_sequins',
        title: 'Sequins',
        size: CardSize.standard,
        front: CardFace(layers: [
          ColorLayer(
            id: 'demo_sequins_bg',
            group: LayerGroup.background,
            zIndex: 0,
            name: 'Background',
            color: const Color(0xFF0D0D0D),
            depthFactor: 1.0,
            shaderConfig: const ShaderConfig(
              shaderAsset: TgcShaders.sequins,
              opacity: 0.92,
              sequinsPalette: 2,
            ),
          ),
          TextLayer(
            id: 'demo_sequins_title',
            group: LayerGroup.layout,
            zIndex: 10,
            name: 'Card Name',
            text: 'SEQUINS',
            fontSize: 36,
            color: Colors.white,
            depthFactor: 0.3,
          ),
        ]),
      );
}
