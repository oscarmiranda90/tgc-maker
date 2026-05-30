import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/demo/demo_card_presets.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/screens/editor_screen.dart';
import 'package:tgc_maker/screens/size_picker_screen.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TGC MAKER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'open-source holographic card engine',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SizePickerScreen(),
                        ),
                      ),
                      child: const Text(
                        'NEW CARD',
                        style: TextStyle(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'DEMO CARDS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  itemCount: DemoCardPresets.all.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final demo = DemoCardPresets.all[i];
                    return _DemoCard(
                      document: demo,
                      shaderPrograms: editor.shaders,
                      onTap: () => _openDemo(context, demo),
                    );
                  },
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  void _openDemo(BuildContext context, CardDocument demo) {
    context.read<CardModel>().setDocument(demo);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final CardDocument document;
  final Map<String, ui.FragmentProgram> shaderPrograms;
  final VoidCallback onTap;

  const _DemoCard({
    required this.document,
    required this.shaderPrograms,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardPreviewWidget(
            document: document,
            shaderPrograms: shaderPrograms,
            maxWidth: 180,
            maxHeight: 260,
          ),
          const SizedBox(height: 10),
          Text(
            document.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
