import 'package:flutter/material.dart';
import 'package:tgc_maker/engine/shader_registry.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/shader_config.dart';
import 'package:tgc_maker/widgets/common/tgc_slider_row.dart';
import 'package:tgc_maker/widgets/shader_picker.dart';

class EffectControls extends StatelessWidget {
  final CardLayer layer;
  final ValueChanged<CardLayer> onChanged;

  const EffectControls({
    super.key,
    required this.layer,
    required this.onChanged,
  });

  void _updateShader(ShaderConfig? cfg) {
    _emit(shaderConfig: cfg, clearShader: cfg == null);
  }

  void _updateOpacity(double v) {
    if (layer.shaderConfig == null) return;
    _emit(shaderConfig: layer.shaderConfig!.copyWith(opacity: v));
  }

  void _updateDepth(double v) => _emit(depthFactor: v);

  void _updateLayerOpacity(double v) => _emit(layerOpacity: v);

  void _updateScale(double v) => _emit(scale: v);

  void _updatePosX(double v) {
    if (layer is ImageLayer) {
      final l = layer as ImageLayer;
      onChanged(l.copyWith(position: Offset(v, l.position.dy)));
    }
  }

  void _updatePosY(double v) {
    if (layer is ImageLayer) {
      final l = layer as ImageLayer;
      onChanged(l.copyWith(position: Offset(l.position.dx, v)));
    }
  }

  void _updateCropX(double v) {
    if (layer is ImageLayer) {
      onChanged((layer as ImageLayer).copyWith(cropX: v));
    }
  }

  void _updateCropY(double v) {
    if (layer is ImageLayer) {
      onChanged((layer as ImageLayer).copyWith(cropY: v));
    }
  }

  void _emit({
    ShaderConfig? shaderConfig,
    bool clearShader = false,
    double? depthFactor,
    double? layerOpacity,
    double? scale,
  }) {
    switch (layer) {
      case ImageLayer l:
        onChanged(l.copyWith(
          shaderConfig: shaderConfig,
          clearShader: clearShader,
          depthFactor: depthFactor,
          opacity: layerOpacity,
          scale: scale,
        ));
      case TextLayer l:
        onChanged(l.copyWith(
          shaderConfig: shaderConfig,
          clearShader: clearShader,
          depthFactor: depthFactor,
          opacity: layerOpacity,
        ));
      case ColorLayer l:
        onChanged(l.copyWith(
          shaderConfig: shaderConfig,
          clearShader: clearShader,
          depthFactor: depthFactor,
          opacity: layerOpacity,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            layer.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          if (layer is ImageLayer) ...[
            _SectionLabel('IMAGE'),
            TgcSliderRow(
              label: 'Scale',
              value: (layer as ImageLayer).scale,
              min: 0.1,
              max: 4.0,
              onChanged: _updateScale,
            ),
            TgcSliderRow(
              label: 'Pos X',
              value: (layer as ImageLayer).position.dx,
              min: -300,
              max: 300,
              divisions: 600,
              onChanged: _updatePosX,
            ),
            TgcSliderRow(
              label: 'Pos Y',
              value: (layer as ImageLayer).position.dy,
              min: -300,
              max: 300,
              divisions: 600,
              onChanged: _updatePosY,
            ),
            TgcSliderRow(
              label: 'Crop X',
              value: (layer as ImageLayer).cropX,
              onChanged: _updateCropX,
            ),
            TgcSliderRow(
              label: 'Crop Y',
              value: (layer as ImageLayer).cropY,
              onChanged: _updateCropY,
            ),
            const SizedBox(height: 20),
            _SectionLabel('LAYER'),
          ],
          TgcSliderRow(
            label: 'Opacity',
            value: layer.opacity,
            onChanged: _updateLayerOpacity,
          ),
          TgcSliderRow(
            label: 'Depth',
            value: layer.depthFactor,
            onChanged: _updateDepth,
          ),
          const SizedBox(height: 20),
          ShaderPicker(
            current: layer.shaderConfig,
            onChanged: _updateShader,
          ),
          if (layer.shaderConfig != null) ...[
            const SizedBox(height: 16),
            TgcSliderRow(
              label: 'Effect',
              value: layer.shaderConfig!.opacity,
              onChanged: _updateOpacity,
            ),
            if (layer.shaderConfig!.shaderAsset == TgcShaders.sequins) ...[
              const SizedBox(height: 12),
              const Text(
                'PALETTE',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (var i = -1; i < 7; i++)
                    _PaletteChip(
                      label: i == -1 ? 'Rnd' : '$i',
                      selected: layer.shaderConfig!.sequinsPalette == i,
                      onTap: () => _updateShader(
                        layer.shaderConfig!.copyWith(sequinsPalette: i),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 9,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? Colors.white : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
