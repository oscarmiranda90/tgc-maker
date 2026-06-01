import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
  static const List<String> _bundledDemoAssets = [
    'assets/cards/demo_card_01.json',
    'assets/cards/demo_card_02.json',
  ];

  List<({String id, String title, DateTime savedAt})> _saved = [];
  bool _seededBundledDemos = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await _seedBundledDemosIfNeeded();
    final cards = await CardStore.listCards();
    if (mounted) setState(() => _saved = cards);
  }

  Future<void> _seedBundledDemosIfNeeded() async {
    if (_seededBundledDemos) return;
    _seededBundledDemos = true;
    await CardStore.seedFromAssetsOnce(
      marker: 'bundled_demo_cards_v1',
      assetPaths: _bundledDemoAssets,
    );
  }

  Future<void> _openSaved(BuildContext context, SavedCard saved) async {
    try {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open card: $e')));
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
                        key: ValueKey(
                          '${entry.id}_${entry.savedAt.toIso8601String()}',
                        ),
                        id: entry.id,
                        title: entry.title,
                        savedAt: entry.savedAt,
                        onOpen: (card) => _openSaved(context, card),
                        onDelete: () => _deleteSaved(entry.id),
                        shaderPrograms: editor.shaders,
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                top: _saved.isEmpty ? 0 : 48,
                left: 28,
                right: 28,
                bottom: 0,
              ),
              sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

class _SavedCardTile extends StatefulWidget {
  final String id;
  final String title;
  final DateTime savedAt;
  final void Function(SavedCard card) onOpen;
  final VoidCallback onDelete;
  final Map<String, ui.FragmentProgram> shaderPrograms;

  const _SavedCardTile({
    super.key,
    required this.id,
    required this.title,
    required this.savedAt,
    required this.onOpen,
    required this.onDelete,
    required this.shaderPrograms,
  });

  @override
  State<_SavedCardTile> createState() => _SavedCardTileState();
}

class _SavedCardTileState extends State<_SavedCardTile> {
  SavedCard? _card;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final card = await CardStore.load(widget.id);
      if (mounted) {
        setState(() {
          _card = card;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _SavedCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id || widget.savedAt != oldWidget.savedAt) {
      setState(() {
        _loading = true;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_card != null) widget.onOpen(_card!);
      },
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 180,
              height: 252,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _loading || _card == null
                    ? Container(
                        color: const Color(0xFF12121A),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 280,
                          height: 400,
                          child: CardPreviewWidget(
                            document: _card!.document,
                            images: _card!.images,
                            shaderPrograms: widget.shaderPrograms,
                            maxWidth: 280,
                            maxHeight: 400,
                            enableParallax: false,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white24,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
