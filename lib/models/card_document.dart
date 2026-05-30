import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/layer_group.dart';

class CardDocument {
  final String id;
  final String title;
  final CardSize size;
  final List<CardLayer> layers;
  final double cornerRadius;
  final double frameWindowInset;
  final double frameWindowRadius;

  const CardDocument({
    required this.id,
    required this.title,
    required this.size,
    required this.layers,
    this.cornerRadius = 18.0,
    this.frameWindowInset = 12.0,
    this.frameWindowRadius = 10.0,
  });

  List<CardLayer> get sortedLayers =>
      [...layers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  List<CardLayer> layersForGroup(LayerGroup group) =>
      layers.where((l) => l.group == group).toList();

  CardDocument copyWith({
    String? title,
    CardSize? size,
    List<CardLayer>? layers,
    double? cornerRadius,
    double? frameWindowInset,
    double? frameWindowRadius,
  }) =>
      CardDocument(
        id: id,
        title: title ?? this.title,
        size: size ?? this.size,
        layers: layers ?? this.layers,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        frameWindowInset: frameWindowInset ?? this.frameWindowInset,
        frameWindowRadius: frameWindowRadius ?? this.frameWindowRadius,
      );

  static CardDocument blank({required CardSize size}) => CardDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Untitled Card',
        size: size,
        layers: const [],
      );
}
