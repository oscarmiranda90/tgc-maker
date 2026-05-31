import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tgc_maker/demo/demo_card_presets.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/persistence/card_store.dart';
import 'package:tgc_maker/screens/editor_screen.dart';
import 'package:tgc_maker/screens/size_picker_screen.dart';
import 'package:tgc_maker/state/card_model.dart';
import 'package:tgc_maker/state/editor_model.dart';
import 'package:tgc_maker/widgets/card_preview_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<({String id, String title, DateTime savedAt})> _saved = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cards = await CardStore.listCards();
    if (mounted) setState(() => _saved = cards);
  }

  Future<void> _openSaved(BuildContext context, String id) async {
    try {
      final saved = await CardStore.load(id);
      if (!context.mounted) return;
      final cardModel = context.read<CardModel>();
      cardModel.setDocument(saved.document);
      for (final e in saved.images.entries) {
        cardModel.addImage(e.key, e.value);
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
      _reload();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open card: $e')),
        );
      }
    }
  }

  Future<void> _deleteSaved(String id) async {
    await CardStore.delete(id);
    _reload();
  }

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
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SizePickerScreen(),
                          ),
                        );
                        _reload();
                      },
                      child: const Text(
                        'NEW CARD',
                        style: TextStyle(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_saved.isNotEmpty) ...[
                      const SizedBox(height: 48),
                      const Text(
                        'MY CARDS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            if (_saved.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    itemCount: _saved.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final entry = _saved[i];
                      return _SavedCardTile(
                        id: entry.id,
                        title: entry.title,
                        onTap: () => _openSaved(context, entry.id),
                        onDelete: () => _deleteSaved(entry.id),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(top: _saved.isEmpty ? 0 : 48, left: 28, right: 28, bottom: 0),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'DEMO CARDS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 16)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  itemCount: DemoCardPresets.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (_, i) {
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

class _SavedCardTile extends StatelessWidget {
  final String id;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedCardTile({
    required this.id,
    required this.title,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder thumbnail (no live render — card not loaded yet)
            Container(
              width: 180,
              height: 252,
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.style_outlined, color: Colors.white12, size: 40),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, color: Colors.white24, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
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
