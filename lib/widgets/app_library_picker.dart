import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/layer_group.dart';
import 'package:tgc_maker/state/card_model.dart';

class AppLibraryPicker extends StatefulWidget {
  final CardModel cardModel;
  final LayerGroup targetGroup;
  final String title;

  const AppLibraryPicker({
    super.key,
    required this.cardModel,
    required this.targetGroup,
    required this.title,
  });

  @override
  State<AppLibraryPicker> createState() => _AppLibraryPickerState();
}

class _AppLibraryPickerState extends State<AppLibraryPicker> {
  List<String> _assets = [];
  String? _loading;

  // Derive a layer name from the asset path: the filename without extension
  // (e.g. 'assets/frames/frame1.png' -> 'frame1').
  String _nameFromAsset(String assetPath) {
    final fileName = assetPath.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return base.isEmpty ? 'image' : base;
  }

  String get _assetPrefix {
    switch (widget.targetGroup) {
      case LayerGroup.layout:
        return 'assets/frames/';
      case LayerGroup.background:
      case LayerGroup.art:
        return 'assets/cards/';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssetList();
  }

  Future<void> _loadAssetList() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();
    final images =
        all
            .where(
              (p) =>
                  p.startsWith(_assetPrefix) &&
                  RegExp(
                    r'\.(png|jpg|jpeg|webp)$',
                    caseSensitive: false,
                  ).hasMatch(p),
            )
            .toList()
          ..sort();
    if (mounted) setState(() => _assets = images);
  }

  Future<void> _pick(String assetPath) async {
    if (_loading != null) return;
    setState(() => _loading = assetPath);
    try {
      final bytes = await rootBundle.load(assetPath);
      final uint8 = bytes.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(uint8);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      widget.cardModel.addLayer(
        ImageLayer(
          id: id,
          group: widget.targetGroup,
          zIndex: widget.cardModel.document.layers.length,
          name: _nameFromAsset(assetPath),
          assetPath: assetPath,
          scale: 1.0,
          depthFactor: 0.3,
        ),
      );
      widget.cardModel.addImage(id, image);

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not load image')));
      }
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text(
                  'APP LIBRARY',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  '${_assets.length} images',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          // Grid
          Expanded(
            child: _assets.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white24,
                    ),
                  )
                : GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: _assets.length,
                    itemBuilder: (_, i) {
                      final path = _assets[i];
                      final isLoading = _loading == path;
                      return GestureDetector(
                        onTap: () => _pick(path),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFF1C1C28),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white24,
                                    size: 24,
                                  ),
                                ),
                              ),
                              if (isLoading)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
