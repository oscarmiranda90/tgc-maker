import 'package:flutter/material.dart';
import 'package:tgc_maker/models/frame_config.dart';
import 'package:tgc_maker/widgets/common/tgc_slider_row.dart';
import 'package:tgc_maker/widgets/shader_picker.dart';

class FrameEditor extends StatelessWidget {
  final FrameConfig? frameConfig;
  final ValueChanged<FrameConfig?> onChanged;

  const FrameEditor({
    super.key,
    required this.frameConfig,
    required this.onChanged,
  });

  FrameConfig get _cfg => frameConfig ?? const FrameConfig();

  @override
  Widget build(BuildContext context) {
    final active = frameConfig != null && frameConfig!.visible;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FRAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Switch(
                value: active,
                onChanged: (on) {
                  if (on) {
                    onChanged(_cfg.copyWith(visible: true));
                  } else {
                    onChanged(_cfg.copyWith(visible: false));
                  }
                },
                activeThumbColor: Colors.white,
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white12,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TgcSliderRow(
            label: 'Thickness',
            value: _cfg.thickness,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            defaultValue: 8.0,
            onChanged: (v) => onChanged(_cfg.copyWith(thickness: v)),
          ),
          TgcSliderRow(
            label: 'Inwards',
            value: _cfg.inwardThickness,
            min: 0.0,
            max: 40.0,
            divisions: 80,
            defaultValue: 0.0,
            onChanged: (v) => onChanged(_cfg.copyWith(inwardThickness: v)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'COLOR',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final c = await showDialog<Color>(
                    context: context,
                    builder: (_) => _ColorPickerDialog(initial: _cfg.color),
                  );
                  if (c != null) onChanged(_cfg.copyWith(color: c));
                },
                child: Container(
                  width: 32,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _cfg.color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ShaderPicker(
            current: _cfg.shaderConfig,
            onChanged: (cfg) => onChanged(
              _cfg.copyWith(shaderConfig: cfg, clearShader: cfg == null),
            ),
          ),
          if (_cfg.shaderConfig != null) ...[
            const SizedBox(height: 16),
            TgcSliderRow(
              label: 'Effect',
              value: _cfg.shaderConfig!.opacity,
              defaultValue: 0.85,
              onChanged: (v) => onChanged(
                _cfg.copyWith(
                  shaderConfig: _cfg.shaderConfig!.copyWith(opacity: v),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r, _g, _b;

  static const _presets = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFCCCCCC),
    Color(0xFF8B0000),
    Color(0xFFFF4444),
    Color(0xFFFF8C00),
    Color(0xFFFFD700),
    Color(0xFF228B22),
    Color(0xFF00CED1),
    Color(0xFF1E90FF),
    Color(0xFF8A2BE2),
    Color(0xFFFF69B4),
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
      title: const Text(
        'Frame Color',
        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1),
      ),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: _current,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
            ),
            const SizedBox(height: 16),
            // Presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _presets)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _r = c.r;
                        _g = c.g;
                        _b = c.b;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _current.toARGB32() == c.toARGB32()
                              ? Colors.white
                              : Colors.white24,
                          width: _current.toARGB32() == c.toARGB32() ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // RGB sliders
            for (final (label, val, set) in [
              ('R', _r, (double v) => setState(() => _r = v)),
              ('G', _g, (double v) => setState(() => _g = v)),
              ('B', _b, (double v) => setState(() => _b = v)),
            ])
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(value: val, min: 0, max: 1, onChanged: set),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
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
