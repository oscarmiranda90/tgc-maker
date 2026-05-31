import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/engine/card_painter.dart';
import 'package:tgc_maker/engine/gloss_painter.dart';
import 'package:tgc_maker/engine/layer_geometry.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/parallax/parallax_card.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class CardPreviewWidget extends StatefulWidget {
  final CardDocument document;
  final Map<String, ui.FragmentProgram> shaderPrograms;
  final Map<String, ui.Image> images;
  final double maxWidth;
  final double maxHeight;
  final bool enableParallax;
  final int? selectedLayerIndex;
  final ValueChanged<int>? onLayerDoubleTap;
  final void Function(int index, Offset delta)? onLayerDrag;

  const CardPreviewWidget({
    super.key,
    required this.document,
    required this.shaderPrograms,
    this.images = const {},
    this.maxWidth = 280,
    this.maxHeight = 420,
    this.enableParallax = true,
    this.selectedLayerIndex,
    this.onLayerDoubleTap,
    this.onLayerDrag,
  });

  @override
  State<CardPreviewWidget> createState() => _CardPreviewWidgetState();
}

class _CardPreviewWidgetState extends State<CardPreviewWidget> {
  bool _isDraggingLayer = false;
  bool _isDraggingMoveHandle = false;

  bool get _interactive =>
      widget.onLayerDoubleTap != null || widget.onLayerDrag != null;

  Size _cardSize() {
    // The frame draws inward as a border, so the widget size is fixed by the
    // document aspect ratio — thickness never grows or zooms the card.
    final aspect = widget.document.size.aspectRatio;
    double width = widget.maxWidth;
    double height = width / aspect;
    if (height > widget.maxHeight) {
      height = widget.maxHeight;
      width = height * aspect;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final size = _cardSize();
    final card = _buildInteractiveCard(size.width, size.height);

    if (!widget.enableParallax) {
      return card;
    }

    return ParallaxCard(
      width: size.width,
      height: size.height,
      clipRadius: widget.document.cornerRadius,
      freezeAtRest: _isDraggingMoveHandle,
      onDoubleTapDown: _interactive
          ? (details) {
              final index = LayerGeometry.hitTestInteractiveLayer(
                widget.document,
                size,
                details.localPosition,
                widget.images,
              );
              if (index != null) {
                widget.onLayerDoubleTap?.call(index);
              }
            }
          : null,
      builder: (tilt) => _buildCardStack(tilt, size.width, size.height),
    );
  }

  Widget _buildInteractiveCard(double width, double height) {
    final card = _buildCardStack(TiltState.zero, width, height);
    if (!_interactive) return card;

    final size = Size(width, height);
    return GestureDetector(
      onDoubleTapDown: (details) {
        final index = LayerGeometry.hitTestInteractiveLayer(
          widget.document,
          size,
          details.localPosition,
          widget.images,
        );
        if (index != null) {
          widget.onLayerDoubleTap?.call(index);
        }
      },
      child: card,
    );
  }

  Widget _buildCardStack(TiltState tilt, double w, double h) {
    final selectedBounds = LayerGeometry.boundsForSelectedLayer(
      widget.document,
      Size(w, h),
      widget.selectedLayerIndex,
      widget.images,
    );

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: CardPainter(
              document: widget.document,
              tiltState: tilt,
              shaderPrograms: widget.shaderPrograms,
              images: widget.images,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GlossPainter(lightX: tilt.lightX, lightY: tilt.lightY),
            ),
          ),
          if (selectedBounds != null)
            Positioned.fromRect(
              rect: selectedBounds.inflate(6),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white70, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (selectedBounds != null && widget.onLayerDrag != null)
            Positioned(
              left: (selectedBounds.right - 18).clamp(8.0, w - 44.0),
              top: (selectedBounds.top - 18).clamp(8.0, h - 44.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  setState(() {
                    _isDraggingLayer = true;
                    _isDraggingMoveHandle = true;
                  });
                },
                onPanUpdate: (details) {
                  final selectedIndex = widget.selectedLayerIndex;
                  if (!_isDraggingLayer || selectedIndex == null) return;
                  widget.onLayerDrag?.call(selectedIndex, details.delta);
                },
                onPanEnd: (_) {
                  setState(() {
                    _isDraggingLayer = false;
                    _isDraggingMoveHandle = false;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _isDraggingLayer = false;
                    _isDraggingMoveHandle = false;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1A24),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.open_with_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
