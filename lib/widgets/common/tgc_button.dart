import 'package:flutter/material.dart';

class TgcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const TgcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onPressed != null ? Colors.white38 : Colors.white12,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: primary ? Colors.black : Colors.white70,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
