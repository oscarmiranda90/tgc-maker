import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';

class CardDocument {
  final String id;
  final String title;
  final CardSize size;
  final double cornerRadius;
  final double frameWindowInset;
  final double frameWindowRadius;

  /// The two sides of the card. Each holds its own layers and frame.
  final CardFace front;
  final CardFace back;

  /// Which side is currently shown / edited.
  final CardSide activeSide;

  const CardDocument({
    required this.id,
    required this.title,
    required this.size,
    this.front = CardFace.empty,
    this.back = CardFace.empty,
    this.activeSide = CardSide.front,
    this.cornerRadius = 18.0,
    this.frameWindowInset = 12.0,
    this.frameWindowRadius = 10.0,
  });

  /// The face currently being shown / edited.
  CardFace get activeFace => activeSide == CardSide.front ? front : back;

  // ── Active-face delegation ─────────────────────────────────────────
  // These mirror the old single-face API so existing call sites keep
  // operating on whichever side is active.

  List<CardLayer> get layers => activeFace.layers;

  FrameConfig? get frameConfig => activeFace.frameConfig;

  List<CardLayer> get sortedLayers => activeFace.sortedLayers;

  List<CardLayer> layersForGroup(LayerGroup group) =>
      activeFace.layersForGroup(group);

  CardDocument copyWith({
    String? title,
    CardSize? size,
    double? cornerRadius,
    double? frameWindowInset,
    double? frameWindowRadius,
    CardFace? front,
    CardFace? back,
    CardSide? activeSide,
    // Active-face shortcuts (apply to the currently active side):
    List<CardLayer>? layers,
    FrameConfig? frameConfig,
    bool clearFrame = false,
  }) {
    final nextActiveSide = activeSide ?? this.activeSide;

    // Resolve the active face after applying any layer/frame shortcuts.
    CardFace resolvedFront = front ?? this.front;
    CardFace resolvedBack = back ?? this.back;

    if (layers != null || frameConfig != null || clearFrame) {
      final target = nextActiveSide == CardSide.front
          ? resolvedFront
          : resolvedBack;
      final updated = target.copyWith(
        layers: layers,
        frameConfig: frameConfig,
        clearFrame: clearFrame,
      );
      if (nextActiveSide == CardSide.front) {
        resolvedFront = updated;
      } else {
        resolvedBack = updated;
      }
    }

    return CardDocument(
      id: id,
      title: title ?? this.title,
      size: size ?? this.size,
      front: resolvedFront,
      back: resolvedBack,
      activeSide: nextActiveSide,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      frameWindowInset: frameWindowInset ?? this.frameWindowInset,
      frameWindowRadius: frameWindowRadius ?? this.frameWindowRadius,
    );
  }

  static CardDocument blank({required CardSize size}) => CardDocument(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'Untitled Card',
    size: size,
  );
}
