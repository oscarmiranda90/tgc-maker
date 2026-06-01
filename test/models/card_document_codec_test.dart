import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/models/shader_config.dart';
import 'package:tgc_maker/persistence/card_document_codec.dart';

void main() {
  test(
    'CardDocumentCodec writes schemaVersion and round-trips fields',
    () async {
      final document = CardDocument(
        id: 'card_1',
        title: 'Contract Test',
        size: CardSize.standard,
        activeSide: CardSide.back,
        cornerRadius: 20,
        frameWindowInset: 14,
        frameWindowRadius: 11,
        front: CardFace(
          layers: const [
            ColorLayer(
              id: 'front_bg',
              group: LayerGroup.background,
              zIndex: 0,
              name: 'Front BG',
              color: Color(0xFF112233),
              gradientColor: Color(0xFF445566),
              gradientDirection: ColorLayerGradientDirection.leftToRight,
            ),
            TextLayer(
              id: 'front_title',
              group: LayerGroup.layout,
              zIndex: 1,
              name: 'Title',
              text: 'HELLO',
              fontSize: 30,
              fontFamily: 'Oswald',
            ),
          ],
          frameConfig: FrameConfig(
            thickness: 9,
            inwardThickness: 2,
            color: Color(0xFFABCDEF),
            shaderConfig: ShaderConfig(
              shaderAsset: 'assets/shaders/holographic.frag',
              opacity: 0.7,
              blendMode: BlendMode.screen,
            ),
          ),
        ),
        back: const CardFace(
          layers: [
            ColorLayer(
              id: 'back_bg',
              group: LayerGroup.background,
              zIndex: 0,
              name: 'Back BG',
              color: Color(0xFF090909),
            ),
          ],
        ),
      );

      final json = await CardDocumentCodec.toJson(document, const {});
      expect(json['schemaVersion'], CardDocumentCodec.currentSchemaVersion);

      final decoded = await CardDocumentCodec.fromJson(json);
      final roundTripped = decoded.document;

      expect(roundTripped.id, document.id);
      expect(roundTripped.title, document.title);
      expect(roundTripped.size.preset, document.size.preset);
      expect(roundTripped.activeSide, document.activeSide);
      expect(roundTripped.front.layers.length, 2);
      expect(roundTripped.back.layers.length, 1);

      final frontText = roundTripped.front.layers[1] as TextLayer;
      expect(frontText.text, 'HELLO');
      expect(frontText.fontFamily, 'Oswald');

      final frontFrame = roundTripped.front.frameConfig;
      expect(frontFrame, isNotNull);
      expect(frontFrame!.inwardThickness, 2);
      expect(frontFrame.shaderConfig, isNotNull);
    },
  );

  test('CardDocumentCodec reads legacy single-face payloads', () async {
    final legacy = <String, dynamic>{
      'id': 'legacy_1',
      'title': 'Legacy Card',
      'size': {
        'preset': 'standard',
        'widthPx': 750,
        'heightPx': 1050,
        'label': 'Standard (63x88 mm)',
      },
      'cornerRadius': 18.0,
      'frameWindowInset': 12.0,
      'frameWindowRadius': 10.0,
      'layers': [
        {
          'type': 'TextLayer',
          'id': 'legacy_title',
          'group': 'layout',
          'zIndex': 1,
          'name': 'Legacy Title',
          'visible': true,
          'opacity': 1.0,
          'posX': 0.0,
          'posY': 0.0,
          'scale': 1.0,
          'rotation': 0.0,
          'depthFactor': 0.0,
          'text': 'LEGACY',
          'fontSize': 28.0,
          'color': 4294967295,
          'align': 'center',
          'fontWeight': 600,
          'fontFamily': 'Roboto',
        },
      ],
    };

    final decoded = await CardDocumentCodec.fromJson(legacy);
    expect(decoded.document.front.layers.length, 1);
    expect(decoded.document.back.layers, isEmpty);
    expect(decoded.document.activeSide, CardSide.front);
  });
}
