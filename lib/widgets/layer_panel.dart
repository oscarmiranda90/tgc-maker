import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/app_library_picker.dart';
import 'package:tgc_maker/widgets/common/rename_dialog.dart';
import 'package:tgc_maker/widgets/layer_tile.dart';

class LayerPanel extends StatelessWidget {
  final void Function(int index)? onLayerTap;

  const LayerPanel({super.key, this.onLayerTap});

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();
    final layers = card.document.sortedLayers;
    final flatItems = _buildFlatItems(layers);
    final dragIndices = {
      for (var i = 0; i < flatItems.length; i++)
        if (flatItems[i].layerId != null) flatItems[i].layerId!: i,
    };

    return Column(
      children: [
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            buildDefaultDragHandles: false,
            onReorderItem: (oldFlat, newFlat) {
              if (oldFlat >= flatItems.length) return;
              final movedItem = flatItems[oldFlat];
              final movedId = movedItem.layerId;
              if (movedId == null) return;

              final remaining = [...flatItems]..removeAt(oldFlat);
              final target = _resolveDropTarget(
                remaining,
                newFlat.clamp(0, remaining.length),
              );

              context.read<CardModel>().reorderLayerById(
                movedId,
                target.group,
                target.beforeId,
              );
            },
            children: [
              for (final group in LayerGroup.values)
                ..._buildGroup(
                  context,
                  group,
                  layers.where((l) => l.group == group).toList(),
                  editor.selectedLayerIndex,
                  layers,
                  dragIndices,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_FlatItem> _buildFlatItems(List<CardLayer> layers) {
    final items = <_FlatItem>[];
    for (final group in LayerGroup.values) {
      items.add(_FlatItem.header(group));
      for (final layer in layers.where((entry) => entry.group == group)) {
        items.add(_FlatItem.layer(layer.id, group));
      }
    }
    return items;
  }

  List<Widget> _buildGroup(
    BuildContext context,
    LayerGroup group,
    List<CardLayer> groupLayers,
    int? selectedIndex,
    List<CardLayer> allLayers,
    Map<String, int> dragIndices,
  ) {
    return [
      _GroupHeader(
        key: ValueKey('header_${group.name}'),
        group: group,
        isEmpty: groupLayers.isEmpty,
        onAddLayer: () => showAddLayerSheet(context, group: group),
      ),
      for (final layer in groupLayers)
        LayerTile(
          key: ValueKey(layer.id),
          layer: layer,
          dragIndex: dragIndices[layer.id] ?? 0,
          selected:
              selectedIndex != null &&
              allLayers.indexOf(layer) == selectedIndex,
          onTap: () {
            final index = allLayers.indexOf(layer);
            context.read<EditorModel>().selectLayer(index);
            onLayerTap?.call(index);
          },
          onRename: () => _renameLayer(context, layer),
          onDuplicate: () => context.read<CardModel>().duplicateLayer(layer.id),
          onToggleVisibility: () =>
              context.read<CardModel>().toggleLayerVisibility(layer.id),
          onDelete: () => context.read<CardModel>().removeLayer(layer.id),
        ),
    ];
  }

  Future<void> _renameLayer(BuildContext context, CardLayer layer) async {
    final cardModel = context.read<CardModel>();
    final name = await showRenameDialog(
      context,
      title: 'Rename Layer',
      initialValue: layer.name,
    );
    if (name != null) cardModel.renameLayer(layer.id, name);
  }
}

String _nextImageName(CardModel cardModel) {
  final count = cardModel.document.layers.whereType<ImageLayer>().length;
  return 'image_${count + 1}';
}

void showAddLayerSheet(BuildContext context, {LayerGroup? group}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) =>
        _AddLayerSheet(cardModel: context.read<CardModel>(), group: group),
  );
}

class _GroupHeader extends StatelessWidget {
  final LayerGroup group;
  final bool isEmpty;
  final VoidCallback onAddLayer;

  const _GroupHeader({
    super.key,
    required this.group,
    required this.isEmpty,
    required this.onAddLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onAddLayer,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1C1C28),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white54),
                ),
              ),
            ],
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: onAddLayer,
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  _emptyHint(group),
                  style: const TextStyle(color: Colors.white12, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _emptyHint(LayerGroup group) {
    switch (group) {
      case LayerGroup.background:
        return 'Add backgrounds here';
      case LayerGroup.art:
        return 'Add art here';
      case LayerGroup.layout:
        return 'Add layout here';
    }
  }
}

class _FlatItem {
  final LayerGroup group;
  final String? layerId;

  const _FlatItem._({required this.group, required this.layerId});

  const _FlatItem.header(LayerGroup group)
    : this._(group: group, layerId: null);

  const _FlatItem.layer(String layerId, LayerGroup group)
    : this._(group: group, layerId: layerId);
}

class _DropTarget {
  final LayerGroup group;
  final String? beforeId;

  const _DropTarget({required this.group, required this.beforeId});
}

_DropTarget _resolveDropTarget(List<_FlatItem> items, int insertionIndex) {
  final next = insertionIndex < items.length ? items[insertionIndex] : null;
  final previous = insertionIndex > 0 ? items[insertionIndex - 1] : null;

  String? firstLayerIdAtOrAfter(int start) {
    for (var i = start; i < items.length; i++) {
      if (items[i].layerId != null) return items[i].layerId;
    }
    return null;
  }

  if (next?.layerId != null) {
    return _DropTarget(group: next!.group, beforeId: next.layerId);
  }

  if (next != null) {
    return _DropTarget(
      group: previous?.group ?? next.group,
      beforeId: firstLayerIdAtOrAfter(insertionIndex + 1),
    );
  }

  return _DropTarget(
    group: previous?.group ?? LayerGroup.background,
    beforeId: null,
  );
}

class _AddLayerSheet extends StatefulWidget {
  final CardModel cardModel;
  final LayerGroup? group;

  const _AddLayerSheet({required this.cardModel, required this.group});

  @override
  State<_AddLayerSheet> createState() => _AddLayerSheetState();
}

class _AddLayerSheetState extends State<_AddLayerSheet> {
  bool _picking = false;

  double _defaultDepthForGroup(LayerGroup group) {
    return group == LayerGroup.art ? 0.3 : 0.0;
  }

  List<_AddAction> get _actions {
    switch (widget.group) {
      case LayerGroup.background:
        return const [
          _AddAction.appLibrary,
          _AddAction.photoLibrary,
          _AddAction.colorBlock,
        ];
      case LayerGroup.art:
        return const [_AddAction.appLibrary, _AddAction.photoLibrary];
      case LayerGroup.layout:
        return const [_AddAction.appLibrary, _AddAction.text];
      case null:
        return const [
          _AddAction.appLibrary,
          _AddAction.photoLibrary,
          _AddAction.colorBlock,
          _AddAction.text,
        ];
    }
  }

  String get _title {
    switch (widget.group) {
      case LayerGroup.background:
        return 'ADD TO BACKGROUND';
      case LayerGroup.art:
        return 'ADD TO ART';
      case LayerGroup.layout:
        return 'ADD TO LAYOUT';
      case null:
        return 'ADD LAYER';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(''),
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          for (final action in _actions)
            ListTile(
              leading: _picking && action == _AddAction.photoLibrary
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : Icon(action.icon, color: Colors.white54),
              title: Text(
                _actionLabel(action),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              onTap: _picking
                  ? null
                  : () {
                      switch (action) {
                        case _AddAction.appLibrary:
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF12121A),
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => AppLibraryPicker(
                              cardModel: widget.cardModel,
                              targetGroup: widget.group ?? LayerGroup.art,
                              title: _groupLabel(
                                widget.group ?? LayerGroup.art,
                              ),
                            ),
                          );
                        case _AddAction.photoLibrary:
                          _pickImage(context, widget.group ?? LayerGroup.art);
                        case _AddAction.colorBlock:
                          _addSimpleLayer(
                            context,
                            'Color Block',
                            LayerGroup.background,
                          );
                          Navigator.pop(context);
                        case _AddAction.text:
                          _addSimpleLayer(context, 'Text', LayerGroup.layout);
                          Navigator.pop(context);
                      }
                    },
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, LayerGroup group) async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final zIndex = widget.cardModel.document.layers.length;
      widget.cardModel.addLayer(
        ImageLayer(
          id: id,
          group: group,
          zIndex: zIndex,
          name: _nextImageName(widget.cardModel),
          imageBytes: bytes,
          scale: 1.0,
          depthFactor: _defaultDepthForGroup(group),
        ),
      );
      widget.cardModel.addImage(id, image);

      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not load image')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _addSimpleLayer(BuildContext context, String type, LayerGroup group) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final zIndex = widget.cardModel.document.layers.length;
    if (type == 'Text') {
      widget.cardModel.addLayer(
        TextLayer(
          id: id,
          group: group,
          zIndex: zIndex,
          name: 'Text Layer',
          text: 'Text',
          depthFactor: 0.0,
        ),
      );
    } else {
      widget.cardModel.addLayer(
        ColorLayer(
          id: id,
          group: group,
          zIndex: zIndex,
          name: 'Color Block',
          color: const Color(0xFF1a1a3a),
          depthFactor: 0.0,
        ),
      );
    }
  }

  String _groupLabel(LayerGroup group) {
    switch (group) {
      case LayerGroup.background:
        return 'BACKGROUND';
      case LayerGroup.art:
        return 'ART';
      case LayerGroup.layout:
        return 'LAYOUT';
    }
  }

  String _actionLabel(_AddAction action) {
    if (action == _AddAction.appLibrary && widget.group == LayerGroup.layout) {
      return 'Layout Library';
    }
    if (action == _AddAction.appLibrary &&
        widget.group == LayerGroup.background) {
      return 'Background Library';
    }
    return action.label;
  }
}

enum _AddAction { appLibrary, photoLibrary, colorBlock, text }

extension on _AddAction {
  IconData get icon {
    switch (this) {
      case _AddAction.appLibrary:
        return Icons.photo_library_outlined;
      case _AddAction.photoLibrary:
        return Icons.image_outlined;
      case _AddAction.colorBlock:
        return Icons.rectangle_outlined;
      case _AddAction.text:
        return Icons.text_fields;
    }
  }

  String get label {
    switch (this) {
      case _AddAction.appLibrary:
        return 'App Library';
      case _AddAction.photoLibrary:
        return 'Photo Library';
      case _AddAction.colorBlock:
        return 'Color Block';
      case _AddAction.text:
        return 'Text';
    }
  }
}
