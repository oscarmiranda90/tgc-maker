import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/screens/editor_screen.dart';
import 'package:tgc_maker/state/card_model.dart';

class SizePickerScreen extends StatefulWidget {
  const SizePickerScreen({super.key});

  @override
  State<SizePickerScreen> createState() => _SizePickerScreenState();
}

class _SizePickerScreenState extends State<SizePickerScreen> {
  CardSize? _selected;
  final _wCtrl = TextEditingController(text: '750');
  final _hCtrl = TextEditingController(text: '1050');

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('SELECT SIZE'),
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CARD SIZE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SizeCard(
                  label: 'Standard',
                  subtitle: '63 × 88 mm',
                  detail: '750 × 1050 px',
                  size: CardSize.standard,
                  selected: _selected == CardSize.standard,
                  onTap: () => setState(() => _selected = CardSize.standard),
                ),
                const SizedBox(width: 16),
                _SizeCard(
                  label: 'Japanese',
                  subtitle: '59 × 86 mm',
                  detail: '700 × 1015 px',
                  size: CardSize.japanese,
                  selected: _selected == CardSize.japanese,
                  onTap: () => setState(() => _selected = CardSize.japanese),
                ),
                const SizedBox(width: 16),
                _SizeCard(
                  label: 'Custom',
                  subtitle: 'Your size',
                  detail: 'Set below',
                  size: CardSize.custom(750, 1050),
                  selected: _selected?.preset == CardSizePreset.custom,
                  onTap: () => setState(() => _selected = CardSize.custom(
                        double.tryParse(_wCtrl.text) ?? 750,
                        double.tryParse(_hCtrl.text) ?? 1050,
                      )),
                ),
              ],
            ),
            if (_selected?.preset == CardSizePreset.custom) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _NumField(
                      label: 'WIDTH (px)',
                      controller: _wCtrl,
                      onChanged: (_) => setState(() => _selected = CardSize.custom(
                            double.tryParse(_wCtrl.text) ?? 750,
                            double.tryParse(_hCtrl.text) ?? 1050,
                          )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NumField(
                      label: 'HEIGHT (px)',
                      controller: _hCtrl,
                      onChanged: (_) => setState(() => _selected = CardSize.custom(
                            double.tryParse(_wCtrl.text) ?? 750,
                            double.tryParse(_hCtrl.text) ?? 1050,
                          )),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _selected != null ? Colors.white : Colors.white12,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _selected == null ? null : _proceed,
                child: const Text(
                  'CREATE CARD',
                  style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceed() {
    final size = _selected!;
    context.read<CardModel>().setDocument(CardDocument.blank(size: size));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String detail;
  final CardSize size;
  final bool selected;
  final VoidCallback onTap;

  const _SizeCard({
    required this.label,
    required this.subtitle,
    required this.detail,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1C1C28) : const Color(0xFF12121A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Colors.white54 : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: size.aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(detail,
                  style: const TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NumField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF12121A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }
}
