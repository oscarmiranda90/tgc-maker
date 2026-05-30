import 'package:flutter/material.dart';
import 'package:tgc_maker/models/card_layer.dart';

class LayerTile extends StatelessWidget {
  final CardLayer layer;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;

  const LayerTile({
    super.key,
    required this.layer,
    required this.selected,
    required this.onTap,
    required this.onToggleVisibility,
  });

  IconData get _typeIcon {
    return switch (layer) {
      ImageLayer _ => Icons.image_outlined,
      TextLayer _ => Icons.text_fields,
      ColorLayer _ => Icons.rectangle_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C1C28) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.white24 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: 0,
              child: const Icon(Icons.drag_handle, color: Colors.white24, size: 16),
            ),
            const SizedBox(width: 8),
            Icon(_typeIcon, color: Colors.white38, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                layer.name,
                style: TextStyle(
                  color: layer.visible ? Colors.white70 : Colors.white24,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (layer.shaderConfig != null)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF7C6AF7),
                  shape: BoxShape.circle,
                ),
              ),
            GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                layer.visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white24,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
