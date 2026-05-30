
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/screens/export_screen.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';
import 'package:tgc_maker/widgets/effect_controls.dart';
import 'package:tgc_maker/widgets/layer_panel.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    return isWide ? const _WideLayout() : const _NarrowLayout();
  }
}

// ── Wide layout (tablet/desktop): 3-panel side-by-side ──────────
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _EditorAppBar(title: card.document.title),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: const LayerPanel(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CardPreviewWidget(
                  document: card.document,
                  shaderPrograms: editor.shaders,
                  images: card.images,
                  maxWidth: 280,
                  maxHeight: 400,
                ),
              ),
            ),
          ),
          if (editor.selectedLayerIndex != null &&
              editor.selectedLayerIndex! < card.document.sortedLayers.length)
            SizedBox(
              width: 260,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.white12)),
                ),
                child: _EffectPanel(
                  layer: card.document.sortedLayers[editor.selectedLayerIndex!],
                  onChanged: (l) => context.read<CardModel>().updateLayer(l.id, l),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Narrow layout (phone): preview always on top, layer list below ──
class _NarrowLayout extends StatefulWidget {
  const _NarrowLayout();

  @override
  State<_NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<_NarrowLayout> {
  bool _editingLayer = false;

  void _openEditor(BuildContext context, int layerIndex) {
    context.read<EditorModel>().selectLayer(layerIndex);
    setState(() => _editingLayer = true);
  }

  void _backToLayers() {
    setState(() => _editingLayer = false);
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();
    final layers = card.document.sortedLayers;
    final idx = editor.selectedLayerIndex;
    final selectedLayer =
        (idx != null && idx < layers.length) ? layers[idx] : null;

    // If selected layer was deleted while editing, go back
    if (_editingLayer && selectedLayer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingLayer = false);
      });
    }

    final previewHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _EditorAppBar(title: card.document.title),
      body: Column(
        children: [
          // Preview always visible
          SizedBox(
            height: previewHeight,
            child: Center(
              child: CardPreviewWidget(
                document: card.document,
                shaderPrograms: editor.shaders,
                images: card.images,
                maxWidth: MediaQuery.sizeOf(context).width - 48,
                maxHeight: previewHeight - 16,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          // Panel header
          _PanelHeader(
            editingLayer: _editingLayer,
            selectedLayer: selectedLayer,
            onBack: _backToLayers,
            onAddLayer: _editingLayer
                ? null
                : () => _showAddMenu(context),
          ),
          const Divider(height: 1, color: Colors.white12),
          // Panel body
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _editingLayer && selectedLayer != null
                  ? KeyedSubtree(
                      key: ValueKey(selectedLayer.id),
                      child: _EffectPanel(
                        layer: selectedLayer,
                        onChanged: (l) =>
                            context.read<CardModel>().updateLayer(l.id, l),
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('layers'),
                      child: LayerPanel(
                        onLayerTap: (index) => _openEditor(context, index),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) => showAddLayerSheet(context);
}

class _PanelHeader extends StatelessWidget {
  final bool editingLayer;
  final CardLayer? selectedLayer;
  final VoidCallback onBack;
  final VoidCallback? onAddLayer;

  const _PanelHeader({
    required this.editingLayer,
    required this.selectedLayer,
    required this.onBack,
    required this.onAddLayer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (editingLayer) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white54, size: 16),
              onPressed: onBack,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                selectedLayer?.name.toUpperCase() ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'LAYERS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
            ),
            const Spacer(),
            if (onAddLayer != null)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white54, size: 20),
                onPressed: onAddLayer,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ],
      ),
    );
  }
}

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _EditorAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      foregroundColor: Colors.white,
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.file_download_outlined, color: Colors.white54),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _EffectPanel extends StatelessWidget {
  final CardLayer layer;
  final ValueChanged<CardLayer> onChanged;

  const _EffectPanel({required this.layer, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return EffectControls(layer: layer, onChanged: onChanged);
  }
}
