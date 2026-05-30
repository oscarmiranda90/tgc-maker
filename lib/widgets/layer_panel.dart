import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/layer_tile.dart';

class LayerPanel extends StatelessWidget {
  final void Function(int index)? onLayerTap;

  const LayerPanel({super.key, this.onLayerTap});

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();
    final layers = card.document.sortedLayers;

    return Column(
      children: [
        if (onLayerTap == null)
          _PanelHeader(onAddLayer: () => _showAddMenu(context)),
        Expanded(
          child: layers.isEmpty
              ? const _EmptyState()
              : ReorderableListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onReorderItem: (o, n) => context.read<CardModel>().reorderLayer(o, n),
                  children: [
                    for (final group in LayerGroup.values)
                      ..._buildGroup(
                        context,
                        group,
                        layers.where((l) => l.group == group).toList(),
                        editor.selectedLayerIndex,
                        layers,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    LayerGroup group,
    List<CardLayer> groupLayers,
    int? selectedIndex,
    List<CardLayer> allLayers,
  ) {
    if (groupLayers.isEmpty) return [];
    return [
      _GroupHeader(key: ValueKey('header_${group.name}'), group: group),
      for (final layer in groupLayers)
        LayerTile(
          key: ValueKey(layer.id),
          layer: layer,
          selected: selectedIndex != null &&
              allLayers.indexOf(layer) == selectedIndex,
          onTap: () {
            final index = allLayers.indexOf(layer);
            context.read<EditorModel>().selectLayer(index);
            onLayerTap?.call(index);
          },
          onToggleVisibility: () =>
              context.read<CardModel>().toggleLayerVisibility(layer.id),
        ),
    ];
  }

  void _showAddMenu(BuildContext context) {
    showAddLayerSheet(context);
  }
}

String _nextImageName(CardModel cardModel) {
  final count = cardModel.document.layers.whereType<ImageLayer>().length;
  return 'image_${count + 1}';
}

void showAddLayerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AddLayerSheet(cardModel: context.read<CardModel>()),
  );
}

class _PanelHeader extends StatelessWidget {
  final VoidCallback onAddLayer;
  const _PanelHeader({required this.onAddLayer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const Text(
            'LAYERS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white54, size: 20),
            onPressed: onAddLayer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final LayerGroup group;
  const _GroupHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        group.label,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 9,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No layers yet.\nTap + to add one.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.8),
      ),
    );
  }
}

class _AddLayerSheet extends StatefulWidget {
  final CardModel cardModel;
  const _AddLayerSheet({required this.cardModel});

  @override
  State<_AddLayerSheet> createState() => _AddLayerSheetState();
}

class _AddLayerSheetState extends State<_AddLayerSheet> {
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD LAYER',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          for (final item in [
            (Icons.image_outlined, 'Image', LayerGroup.art),
            (Icons.rectangle_outlined, 'Color Block', LayerGroup.background),
            (Icons.text_fields, 'Text', LayerGroup.layout),
          ])
            ListTile(
              leading: _picking && item.$2 == 'Image'
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    )
                  : Icon(item.$1, color: Colors.white54),
              title: Text(item.$2,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              onTap: _picking
                  ? null
                  : () {
                      if (item.$2 == 'Image') {
                        _pickImage(context);
                      } else {
                        _addSimpleLayer(item.$2, item.$3);
                        Navigator.pop(context);
                      }
                    },
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    setState(() => _picking = true);
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final zIndex = widget.cardModel.document.layers.length;
      widget.cardModel.addLayer(ImageLayer(
        id: id,
        group: LayerGroup.art,
        zIndex: zIndex,
        name: _nextImageName(widget.cardModel),
        imageBytes: bytes,
        scale: 1.0,
        depthFactor: 0.3,
      ));
      widget.cardModel.addImage(id, image);

      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load image')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _addSimpleLayer(String type, LayerGroup group) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final zIndex = widget.cardModel.document.layers.length;
    if (type == 'Text') {
      widget.cardModel.addLayer(TextLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: 'Text Layer',
        text: 'Text',
        depthFactor: 0.0,
      ));
    } else {
      widget.cardModel.addLayer(ColorLayer(
        id: id,
        group: group,
        zIndex: zIndex,
        name: 'Color Block',
        color: const Color(0xFF1a1a3a),
        depthFactor: 0.5,
      ));
    }
  }
}
