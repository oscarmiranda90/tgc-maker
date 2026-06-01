import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tgc_maker/engine/card_painter.dart';
import 'package:tgc_maker/engine/gloss_painter.dart';
import 'package:tgc_maker/models/card_face.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
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
              child: CardPreviewWidget(
                document: card.document,
                shaderPrograms: editor.shaders,
                images: card.images,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
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
      final card = context.read<CardModel>();
      final editor = context.read<EditorModel>();
      final frontBytes = await _renderSidePng(CardSide.front, card, editor);
      final backBytes = await _renderSidePng(CardSide.back, card, editor);

      final baseName = _safeFileName(card.document.title);
      final files = [
        XFile.fromData(
          frontBytes,
          mimeType: 'image/png',
          name: '${baseName}_front.png',
        ),
        XFile.fromData(
          backBytes,
          mimeType: 'image/png',
          name: '${baseName}_back.png',
        ),
      ];
      await SharePlus.instance.share(ShareParams(files: files));
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _renderSidePng(
    CardSide side,
    CardModel card,
    EditorModel editor,
  ) async {
    final doc = card.document.copyWith(activeSide: side);
    final width = doc.size.widthPx.round();
    final height = doc.size.heightPx.round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    const tilt = TiltState.zero;

    CardPainter(
      document: doc,
      tiltState: tilt,
      shaderPrograms: editor.shaders,
      images: card.images,
    ).paint(canvas, size);
    const GlossPainter(lightX: 0.0, lightY: 0.0).paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode export image for ${side.name} side.');
    }
    return byteData.buffer.asUint8List();
  }

  String _safeFileName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'card';
    final cleaned = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return cleaned.replaceAll(RegExp(r'_+'), '_');
  }
}
