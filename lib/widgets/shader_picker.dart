import 'package:flutter/material.dart';
import 'package:tgc_maker/engine/shader_registry.dart';
import 'package:tgc_maker/models/shader_config.dart';

class ShaderPicker extends StatelessWidget {
  final ShaderConfig? current;
  final ValueChanged<ShaderConfig?> onChanged;

  const ShaderPicker({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SHADER EFFECT',
          style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ShaderChip(
              label: 'None',
              selected: current == null,
              onTap: () => onChanged(null),
            ),
            for (var i = 0; i < TgcShaders.all.length; i++)
              _ShaderChip(
                label: TgcShaders.labels[i],
                selected: current?.shaderAsset == TgcShaders.all[i],
                onTap: () => onChanged(
                  current?.shaderAsset == TgcShaders.all[i]
                      ? null
                      : ShaderConfig(shaderAsset: TgcShaders.all[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShaderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShaderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.white : Colors.white12,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.black : Colors.white54,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
