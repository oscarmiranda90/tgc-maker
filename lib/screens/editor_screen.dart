import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/persistence/card_store.dart';
import 'package:tgc_maker/screens/export_screen.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';
import 'package:tgc_maker/widgets/common/rename_dialog.dart';
import 'package:tgc_maker/widgets/effect_controls.dart';
import 'package:tgc_maker/widgets/frame_editor.dart';
import 'package:tgc_maker/widgets/layer_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _isSaved = true;
  bool _saving = false;
  CardModel? _cardModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<CardModel>();
    if (next != _cardModel) {
      _cardModel?.removeListener(_onCardChanged);
      _cardModel = next;
      _cardModel!.addListener(_onCardChanged);
    }
  }

  @override
  void dispose() {
    _cardModel?.removeListener(_onCardChanged);
    super.dispose();
  }

  void _onCardChanged() {
    if (_isSaved) setState(() => _isSaved = false);
  }

  Future<bool> _save() async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final card = context.read<CardModel>();
      await CardStore.save(card.document, card.images);
      if (mounted) setState(() => _isSaved = true);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onPopRequested() async {
    if (_isSaved) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        title: const Text(
          'Unsaved changes',
          style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1),
        ),
        content: const Text(
          'Save your card before leaving?',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      final ok = await _save();
      return ok;
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    return _EditorScope(
      isSaved: _isSaved,
      saving: _saving,
      onSave: _save,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final canPop = await _onPopRequested();
          if (canPop && context.mounted) Navigator.of(context).pop();
        },
        child: isWide ? const _WideLayout() : const _NarrowLayout(),
      ),
    );
  }
}

// Passes save state down to AppBar without prop drilling
class _EditorScope extends InheritedWidget {
  final bool isSaved;
  final bool saving;
  final Future<bool> Function() onSave;

  const _EditorScope({
    required this.isSaved,
    required this.saving,
    required this.onSave,
    required super.child,
  });

  static _EditorScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EditorScope>()!;

  @override
  bool updateShouldNotify(_EditorScope old) =>
      isSaved != old.isSaved || saving != old.saving;
}

// ── Wide layout (tablet/desktop): 3-panel side-by-side ──────────
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  void _selectLayer(BuildContext context, int layerIndex) {
    context.read<EditorModel>().selectLayer(layerIndex);
  }

  void _moveSelectedLayer(BuildContext context, int layerIndex, Offset delta) {
    final card = context.read<CardModel>();
    final layers = card.document.sortedLayers;
    if (layerIndex < 0 || layerIndex >= layers.length) return;
    final layer = layers[layerIndex];
    switch (layer) {
      case ImageLayer image:
        card.updateLayer(
          image.id,
          image.copyWith(position: image.position + delta),
        );
      case TextLayer text:
        card.updateLayer(
          text.id,
          text.copyWith(position: text.position + delta),
        );
      default:
        return;
    }
  }

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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<EditorModel>().selectLayer(null),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CardPreviewWidget(
                    document: card.document,
                    shaderPrograms: editor.shaders,
                    images: card.images,
                    maxWidth: 280,
                    maxHeight: 400,
                    selectedLayerIndex: editor.selectedLayerIndex,
                    onLayerDoubleTap: (index) => _selectLayer(context, index),
                    onLayerDrag: (index, delta) =>
                        _moveSelectedLayer(context, index, delta),
                  ),
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
                  onChanged: (l) =>
                      context.read<CardModel>().updateLayer(l.id, l),
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

enum _Panel { layers, layer, frame }

class _NarrowLayoutState extends State<_NarrowLayout> {
  _Panel _panel = _Panel.layers;

  void _openLayerEditor(BuildContext context, int layerIndex) {
    context.read<EditorModel>().selectLayer(layerIndex);
    setState(() => _panel = _Panel.layer);
  }

  void _back() => setState(() => _panel = _Panel.layers);

  void _moveSelectedLayer(BuildContext context, int layerIndex, Offset delta) {
    final card = context.read<CardModel>();
    final layers = card.document.sortedLayers;
    if (layerIndex < 0 || layerIndex >= layers.length) return;
    final layer = layers[layerIndex];
    switch (layer) {
      case ImageLayer image:
        card.updateLayer(
          image.id,
          image.copyWith(position: image.position + delta),
        );
      case TextLayer text:
        card.updateLayer(
          text.id,
          text.copyWith(position: text.position + delta),
        );
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();
    final layers = card.document.sortedLayers;
    final idx = editor.selectedLayerIndex;
    final selectedLayer = (idx != null && idx < layers.length)
        ? layers[idx]
        : null;

    if (_panel == _Panel.layer && selectedLayer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _panel = _Panel.layers);
      });
    }

    final previewHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _EditorAppBar(title: card.document.title),
      body: Column(
        children: [
          SizedBox(
            height: previewHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<EditorModel>().selectLayer(null),
              child: Center(
                child: CardPreviewWidget(
                  document: card.document,
                  shaderPrograms: editor.shaders,
                  images: card.images,
                  maxWidth: MediaQuery.sizeOf(context).width - 48,
                  maxHeight: previewHeight - 16,
                  selectedLayerIndex: editor.selectedLayerIndex,
                  onLayerDoubleTap: (index) => _openLayerEditor(context, index),
                  onLayerDrag: (index, delta) =>
                      _moveSelectedLayer(context, index, delta),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          _PanelHeader(
            panel: _panel,
            selectedLayer: selectedLayer,
            onBack: _back,
            onAddLayer: _panel == _Panel.layers
                ? () => showAddLayerSheet(context)
                : null,
            onFrameTap: _panel == _Panel.layers
                ? () => setState(() => _panel = _Panel.frame)
                : null,
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_panel) {
                _Panel.layer when selectedLayer != null => KeyedSubtree(
                  key: ValueKey(selectedLayer.id),
                  child: _EffectPanel(
                    layer: selectedLayer,
                    onChanged: (l) =>
                        context.read<CardModel>().updateLayer(l.id, l),
                  ),
                ),
                _Panel.frame => KeyedSubtree(
                  key: const ValueKey('frame'),
                  child: FrameEditor(
                    frameConfig: card.document.frameConfig,
                    onChanged: (cfg) => context.read<CardModel>().setFrame(cfg),
                  ),
                ),
                _ => KeyedSubtree(
                  key: const ValueKey('layers'),
                  child: LayerPanel(
                    onLayerTap: (i) => _openLayerEditor(context, i),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final _Panel panel;
  final CardLayer? selectedLayer;
  final VoidCallback onBack;
  final VoidCallback? onAddLayer;
  final VoidCallback? onFrameTap;

  const _PanelHeader({
    required this.panel,
    required this.selectedLayer,
    required this.onBack,
    required this.onAddLayer,
    required this.onFrameTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (panel != _Panel.layers) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white54,
                size: 16,
              ),
              onPressed: onBack,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                panel == _Panel.frame
                    ? 'FRAME'
                    : (selectedLayer?.name.toUpperCase() ?? ''),
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
            IconButton(
              icon: const Icon(
                Icons.border_style_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: onFrameTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'Frame',
            ),
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
    final scope = _EditorScope.of(context);
    final card = context.watch<CardModel>();
    final frameVisible = card.document.frameConfig?.visible ?? false;

    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      foregroundColor: Colors.white,
      title: GestureDetector(
        onTap: () async {
          final cardModel = context.read<CardModel>();
          final name = await showRenameDialog(
            context,
            title: 'Rename Card',
            initialValue: cardModel.document.title,
          );
          if (name != null) cardModel.setTitle(name);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 13, color: Colors.white24),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            frameVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: frameVisible ? Colors.white54 : Colors.white24,
          ),
          tooltip: frameVisible ? 'Hide frame' : 'Show frame',
          onPressed: () => context.read<CardModel>().toggleFrameVisibility(),
        ),
        if (scope.saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(
              scope.isSaved ? Icons.save_outlined : Icons.save,
              color: scope.isSaved ? Colors.white24 : Colors.white70,
            ),
            tooltip: 'Save',
            onPressed: () => scope.onSave(),
          ),
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
