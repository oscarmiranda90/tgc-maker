import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/persistence/card_document_codec.dart';

class SavedCard {
  final CardDocument document;
  final Map<String, ui.Image> images;

  const SavedCard({required this.document, required this.images});
}

class CardStore {
  static Future<Directory> _cardsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/tgc_cards');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _cardFile(String id) async {
    final dir = await _cardsDir();
    return File('${dir.path}/$id.json');
  }

  // ── List all saved card IDs + titles ─────────────────────────────
  static Future<List<({String id, String title, DateTime savedAt})>>
  listCards() async {
    final dir = await _cardsDir();
    final files = await dir
        .list()
        .where((e) => e.path.endsWith('.json'))
        .toList();

    final result = <({String id, String title, DateTime savedAt})>[];
    for (final f in files) {
      try {
        final raw = await File(f.path).readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        result.add((
          id: json['id'] as String,
          title: json['title'] as String,
          savedAt: DateTime.parse(json['savedAt'] as String),
        ));
      } catch (_) {}
    }
    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }

  // ── Save ─────────────────────────────────────────────────────────
  static Future<void> save(
    CardDocument doc,
    Map<String, ui.Image> images,
  ) async {
    final file = await _cardFile(doc.id);
    final json = await CardDocumentCodec.toJson(doc, images);
    json['savedAt'] = DateTime.now().toIso8601String();
    await file.writeAsString(jsonEncode(json));
  }

  /// Imports a serialized saved-card JSON payload into the local card store.
  /// If [overwrite] is false and a card with the same ID exists, it is kept.
  static Future<void> importJsonString(
    String raw, {
    bool overwrite = false,
  }) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Saved card JSON must be an object');
    }
    final map = decoded.cast<String, dynamic>();
    final id = map['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Saved card JSON is missing a valid id');
    }

    final file = await _cardFile(id);
    if (!overwrite && await file.exists()) return;

    map['savedAt'] ??= DateTime.now().toIso8601String();
    await file.writeAsString(jsonEncode(map));
  }

  /// Imports bundled saved cards from assets exactly once for a given marker.
  static Future<void> seedFromAssetsOnce({
    required String marker,
    required List<String> assetPaths,
  }) async {
    final dir = await _cardsDir();
    final markerFile = File('${dir.path}/.$marker.seeded');
    if (await markerFile.exists()) return;

    for (final assetPath in assetPaths) {
      try {
        final raw = await rootBundle.loadString(assetPath);
        await importJsonString(raw, overwrite: false);
      } catch (_) {
        // Skip invalid/missing demo assets so one bad file doesn't block seed.
      }
    }

    await markerFile.writeAsString(DateTime.now().toIso8601String());
  }

  // ── Load ─────────────────────────────────────────────────────────
  static Future<SavedCard> load(String id) async {
    final file = await _cardFile(id);
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final decoded = await CardDocumentCodec.fromJson(json);
    return SavedCard(document: decoded.document, images: decoded.images);
  }

  // ── Delete ───────────────────────────────────────────────────────
  static Future<void> delete(String id) async {
    final file = await _cardFile(id);
    if (await file.exists()) await file.delete();
  }
}
