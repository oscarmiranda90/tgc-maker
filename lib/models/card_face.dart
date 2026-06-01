import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/models/layer_group.dart';

/// Which side of the card is being shown / edited.
enum CardSide { front, back }

/// One side of a card: its own stack of layers and frame configuration.
class CardFace {
  final List<CardLayer> layers;
  final FrameConfig? frameConfig;

  const CardFace({this.layers = const [], this.frameConfig});

  List<CardLayer> get sortedLayers =>
      [...layers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  List<CardLayer> layersForGroup(LayerGroup group) =>
      layers.where((l) => l.group == group).toList();

  CardFace copyWith({
    List<CardLayer>? layers,
    FrameConfig? frameConfig,
    bool clearFrame = false,
  }) => CardFace(
    layers: layers ?? this.layers,
    frameConfig: clearFrame ? null : (frameConfig ?? this.frameConfig),
  );

  static const CardFace empty = CardFace();
}
