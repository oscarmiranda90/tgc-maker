import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/engine/shader_registry.dart';
import 'package:tgc_maker/engine/text_fonts.dart';
import 'package:tgc_maker/models/card_layer.dart';
import 'package:tgc_maker/models/shader_config.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/widgets/common/tgc_slider_row.dart';
import 'package:tgc_maker/widgets/shader_picker.dart';

class EffectControls extends StatefulWidget {
  final CardLayer layer;
  final ValueChanged<CardLayer> onChanged;

  const EffectControls({
    super.key,
    required this.layer,
    required this.onChanged,
  });

  @override
  State<EffectControls> createState() => _EffectControlsState();
}

class _EffectControlsState extends State<EffectControls> {
  static Future<void>? _backgroundRemoverInitialization;

  CardLayer get layer => widget.layer;

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
      widget.onChanged(l.copyWith(position: Offset(v, l.position.dy)));
    }
  }

  void _updatePosY(double v) {
    if (layer is ImageLayer) {
      final l = layer as ImageLayer;
      widget.onChanged(l.copyWith(position: Offset(l.position.dx, v)));
    }
  }

  void _updateCropX(double v) {
    if (layer is ImageLayer) {
      widget.onChanged((layer as ImageLayer).copyWith(cropX: v));
    }
  }

  void _updateCropY(double v) {
    if (layer is ImageLayer) {
      widget.onChanged((layer as ImageLayer).copyWith(cropY: v));
    }
  }

  void _updateColorLayerColor(Color color) {
    if (layer is ColorLayer) {
      widget.onChanged((layer as ColorLayer).copyWith(color: color));
    }
  }

  void _updateColorLayerGradient(Color? color) {
    if (layer is! ColorLayer) return;
    final colorLayer = layer as ColorLayer;
    widget.onChanged(
      color == null
          ? colorLayer.copyWith(clearGradient: true)
          : colorLayer.copyWith(gradientColor: color),
    );
  }

  void _updateColorLayerGradientDirection(
    ColorLayerGradientDirection direction,
  ) {
    if (layer is ColorLayer) {
      widget.onChanged(
        (layer as ColorLayer).copyWith(gradientDirection: direction),
      );
    }
  }

  void _updateText(String value) {
    if (layer is TextLayer) {
      widget.onChanged(
        (layer as TextLayer).copyWith(text: value, name: _nameFromText(value)),
      );
    }
  }

  // Derive a layer name from the written text: first non-empty line, trimmed
  // and capped so the layer list stays tidy. Falls back when empty.
  String _nameFromText(String text) {
    final firstLine = text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) return 'Text Layer';
    return firstLine.length > 24 ? '${firstLine.substring(0, 24)}…' : firstLine;
  }

  void _updateFontSize(double v) {
    if (layer is TextLayer) {
      widget.onChanged((layer as TextLayer).copyWith(fontSize: v));
    }
  }

  void _updateTextColor(Color color) {
    if (layer is TextLayer) {
      widget.onChanged((layer as TextLayer).copyWith(color: color));
    }
  }

  void _updateTextAlign(TextAlign align) {
    if (layer is TextLayer) {
      widget.onChanged((layer as TextLayer).copyWith(align: align));
    }
  }

  void _updateFontWeight(FontWeight weight) {
    if (layer is TextLayer) {
      widget.onChanged((layer as TextLayer).copyWith(fontWeight: weight));
    }
  }

  void _updateFontFamily(String family) {
    if (layer is TextLayer) {
      TextFonts.ensureLoaded(family);
      widget.onChanged((layer as TextLayer).copyWith(fontFamily: family));
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
        widget.onChanged(
          l.copyWith(
            shaderConfig: shaderConfig,
            clearShader: clearShader,
            depthFactor: depthFactor,
            opacity: layerOpacity,
            scale: scale,
          ),
        );
      case TextLayer l:
        widget.onChanged(
          l.copyWith(
            shaderConfig: shaderConfig,
            clearShader: clearShader,
            depthFactor: depthFactor,
            opacity: layerOpacity,
          ),
        );
      case ColorLayer l:
        widget.onChanged(
          l.copyWith(
            shaderConfig: shaderConfig,
            clearShader: clearShader,
            depthFactor: depthFactor,
            opacity: layerOpacity,
          ),
        );
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
              defaultValue: 1.0,
              onChanged: _updateScale,
            ),
            TgcSliderRow(
              label: 'Pos X',
              value: (layer as ImageLayer).position.dx,
              min: -300,
              max: 300,
              divisions: 600,
              defaultValue: 0,
              onChanged: _updatePosX,
            ),
            TgcSliderRow(
              label: 'Pos Y',
              value: (layer as ImageLayer).position.dy,
              min: -300,
              max: 300,
              divisions: 600,
              defaultValue: 0,
              onChanged: _updatePosY,
            ),
            TgcSliderRow(
              label: 'Crop X',
              value: (layer as ImageLayer).cropX,
              defaultValue: 0,
              onChanged: _updateCropX,
            ),
            TgcSliderRow(
              label: 'Crop Y',
              value: (layer as ImageLayer).cropY,
              defaultValue: 0,
              onChanged: _updateCropY,
            ),
            const SizedBox(height: 20),
            _SectionLabel('LAYER'),
          ],
          if (layer is TextLayer) ...[
            _SectionLabel('TEXT'),
            _TextEditField(
              key: ValueKey('text_${layer.id}'),
              value: (layer as TextLayer).text,
              onChanged: _updateText,
            ),
            const SizedBox(height: 12),
            TgcSliderRow(
              label: 'Size',
              value: (layer as TextLayer).fontSize,
              min: 8,
              max: 120,
              divisions: 112,
              defaultValue: 24,
              onChanged: _updateFontSize,
            ),
            const SizedBox(height: 8),
            _ColorRow(
              label: 'Color',
              color: (layer as TextLayer).color,
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (_) => _ColorPickerDialog(
                    title: 'Text Color',
                    initial: (layer as TextLayer).color,
                  ),
                );
                if (color != null) _updateTextColor(color);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'ALIGN',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final (align, label) in const [
                  (TextAlign.left, 'L'),
                  (TextAlign.center, 'C'),
                  (TextAlign.right, 'R'),
                ])
                  _DirectionChip(
                    label: label,
                    selected: (layer as TextLayer).align == align,
                    onTap: () => _updateTextAlign(align),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'FONT',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final font in TextFonts.keys)
                  _FontChip(
                    family: font,
                    selected: (layer as TextLayer).fontFamily == font,
                    onTap: () => _updateFontFamily(font),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'WEIGHT',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final (weight, label) in const [
                  (FontWeight.w400, 'R'),
                  (FontWeight.w600, 'M'),
                  (FontWeight.w700, 'B'),
                  (FontWeight.w900, 'X'),
                ])
                  _DirectionChip(
                    label: label,
                    selected: (layer as TextLayer).fontWeight == weight,
                    onTap: () => _updateFontWeight(weight),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionLabel('LAYER'),
          ],
          TgcSliderRow(
            label: 'Opacity',
            value: layer.opacity,
            defaultValue: 1.0,
            onChanged: _updateLayerOpacity,
          ),
          TgcSliderRow(
            label: 'Depth',
            value: layer.depthFactor,
            defaultValue: 0.0,
            onChanged: _updateDepth,
          ),
          if (layer is ColorLayer) ...[
            const SizedBox(height: 20),
            _SectionLabel('COLOR'),
            _ColorRow(
              label: 'Base',
              color: (layer as ColorLayer).color,
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (_) => _ColorPickerDialog(
                    title: 'Block Color',
                    initial: (layer as ColorLayer).color,
                  ),
                );
                if (color != null) _updateColorLayerColor(color);
              },
            ),
            const SizedBox(height: 12),
            _ColorRow(
              label: 'Gradient',
              color: (layer as ColorLayer).gradientColor,
              onTap: () async {
                final current = (layer as ColorLayer).gradientColor;
                final color = await showDialog<Color?>(
                  context: context,
                  builder: (_) => _ColorPickerDialog(
                    title: 'Gradient Color',
                    initial: current ?? (layer as ColorLayer).color,
                    allowClear: current != null,
                  ),
                );
                _updateColorLayerGradient(color);
              },
            ),
            if ((layer as ColorLayer).gradientColor != null) ...[
              const SizedBox(height: 12),
              const Text(
                'GRADIENT DIRECTION',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final direction in ColorLayerGradientDirection.values)
                    _DirectionChip(
                      label: switch (direction) {
                        ColorLayerGradientDirection.topToBottom => 'TB',
                        ColorLayerGradientDirection.leftToRight => 'LR',
                        ColorLayerGradientDirection.topLeftToBottomRight =>
                          'D1',
                        ColorLayerGradientDirection.bottomLeftToTopRight =>
                          'D2',
                      },
                      selected:
                          (layer as ColorLayer).gradientDirection == direction,
                      onTap: () =>
                          _updateColorLayerGradientDirection(direction),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 20),
          ShaderPicker(current: layer.shaderConfig, onChanged: _updateShader),
          if (layer.shaderConfig != null) ...[
            const SizedBox(height: 16),
            TgcSliderRow(
              label: 'Effect',
              value: layer.shaderConfig!.opacity,
              defaultValue: 0.85,
              onChanged: _updateOpacity,
            ),
            if (layer.shaderConfig!.shaderAsset == TgcShaders.sequins) ...[
              const SizedBox(height: 12),
              const Text(
                'PALETTE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
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
          if (layer is ImageLayer) ...[
            const SizedBox(height: 20),
            _SectionLabel('TOOLS'),
            _RemoveBackgroundButton(layer: layer as ImageLayer),
          ],
        ],
      ),
    );
  }
}

class _RemoveBackgroundButton extends StatefulWidget {
  final ImageLayer layer;

  const _RemoveBackgroundButton({required this.layer});

  @override
  State<_RemoveBackgroundButton> createState() =>
      _RemoveBackgroundButtonState();
}

class _RemoveBackgroundButtonState extends State<_RemoveBackgroundButton> {
  bool _busy = false;
  // Cutout strength. Lower = keep more of the subject (softer removal).
  double _strength = 0.5;
  // Untouched source, captured before the first removal so re-running with a
  // different strength always works from the full image, not a prior cutout.
  Uint8List? _originalBytes;
  // True once a removal is applied, so we can offer undo.
  bool _removed = false;

  Future<void> _removeBackground() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final imageBytes = _originalBytes ??= await _loadSourceBytes();
      await (_EffectControlsState._backgroundRemoverInitialization ??=
          BackgroundRemover.instance.initializeOrt());
      final resultBytes = await BackgroundRemover.instance.removeBgBytes(
        imageBytes,
        threshold: _strength,
      );
      if (!mounted) return;
      await context.read<CardModel>().replaceImageLayerSource(
        widget.layer.id,
        resultBytes,
      );
      if (!mounted) return;
      setState(() => _removed = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Background removed')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Background removal failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    if (_busy || _originalBytes == null) return;
    setState(() => _busy = true);
    try {
      await context.read<CardModel>().replaceImageLayerSource(
        widget.layer.id,
        _originalBytes!,
      );
      if (!mounted) return;
      setState(() => _removed = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Restored original')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _loadSourceBytes() async {
    if (widget.layer.imageBytes != null) {
      return widget.layer.imageBytes!;
    }
    if (widget.layer.assetPath != null) {
      final asset = await rootBundle.load(widget.layer.assetPath!);
      return asset.buffer.asUint8List();
    }
    throw StateError('Image data is not available for this layer.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TgcSliderRow(
          label: 'Cutout',
          value: _strength,
          min: 0.1,
          max: 0.9,
          divisions: 80,
          defaultValue: 0.5,
          onChanged: (v) {
            if (_busy) return;
            setState(() => _strength = v);
          },
        ),
        const SizedBox(height: 4),
        const Text(
          'Lower keeps more of the subject',
          style: TextStyle(color: Colors.white24, fontSize: 9),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _removeBackground,
            icon: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_outlined, size: 16),
            label: Text(
              _busy
                  ? 'Removing...'
                  : (_originalBytes != null ? 'Re-run BG' : 'Remove BG'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (_removed) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _busy ? null : _undo,
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Undo removal'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TextEditField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TextEditField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TextEditField> createState() => _TextEditFieldState();
}

class _TextEditFieldState extends State<_TextEditField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextEditField old) {
    super.didUpdateWidget(old);
    // Sync external changes (e.g. reset) without clobbering active typing.
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: null,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Type text...',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: const Color(0xFF12121A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white38),
        ),
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

class _ColorRow extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? const Color(0x0012121A),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: color == null ? Colors.white12 : Colors.white24,
              ),
            ),
            child: color == null
                ? const Icon(Icons.remove, size: 14, color: Colors.white24)
                : null,
          ),
        ),
      ],
    );
  }
}

class _FontChip extends StatelessWidget {
  final String family;
  final bool selected;
  final VoidCallback onTap;

  const _FontChip({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Colors.white : Colors.white12),
        ),
        child: Text(
          family,
          // Preview each option in its own typeface.
          style: TextFonts.style(
            family,
            base: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
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

class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initial;
  final bool allowClear;

  const _ColorPickerDialog({
    required this.title,
    required this.initial,
    this.allowClear = false,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r;
  late double _g;
  late double _b;

  static const _presets = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFE53935),
    Color(0xFFFFA726),
    Color(0xFFFFEE58),
    Color(0xFF43A047),
    Color(0xFF00ACC1),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
  ];

  @override
  void initState() {
    super.initState();
    _r = widget.initial.r;
    _g = widget.initial.g;
    _b = widget.initial.b;
  }

  Color get _current => Color.from(alpha: 1, red: _r, green: _g, blue: _b);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12121A),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: _current,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in _presets)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _r = color.r;
                        _g = color.g;
                        _b = color.b;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _current.toARGB32() == color.toARGB32()
                              ? Colors.white
                              : Colors.white24,
                          width: _current.toARGB32() == color.toARGB32()
                              ? 2
                              : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final slider in [
              ('R', _r, (double value) => setState(() => _r = value)),
              ('G', _g, (double value) => setState(() => _g = value)),
              ('B', _b, (double value) => setState(() => _b = value)),
            ])
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      slider.$1,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: slider.$2,
                      min: 0,
                      max: 1,
                      onChanged: slider.$3,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        if (widget.allowClear)
          TextButton(
            onPressed: () => Navigator.pop<Color?>(context, null),
            child: const Text('Clear', style: TextStyle(color: Colors.white38)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _current),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
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
