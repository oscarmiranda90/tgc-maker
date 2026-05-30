
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _repaintKey = GlobalKey();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardModel>();
    final editor = context.watch<EditorModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('EXPORT'),
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: CardPreviewWidget(
                document: card.document,
                shaderPrograms: editor.shaders,
                maxWidth: 280,
                maxHeight: 400,
                enableParallax: false,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${card.document.size.widthPx.toInt()} × ${card.document.size.heightPx.toInt()} px',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            if (_exporting)
              const CircularProgressIndicator(
                color: Colors.white38,
                strokeWidth: 1.5,
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _export,
                child: const Text(
                  'SAVE / SHARE',
                  style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final file = XFile.fromData(bytes, mimeType: 'image/png', name: 'card.png');
      await SharePlus.instance.share(ShareParams(files: [file]));
    } finally {
      setState(() => _exporting = false);
    }
  }
}
