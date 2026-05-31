import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central catalog of Google Fonts available for text layers.
///
/// Each entry maps a stable key (stored on the layer + persisted) to a
/// [GoogleFonts] builder. The builder both resolves the registered font family
/// name and triggers the font to load on first use.
class TextFonts {
  TextFonts._();

  /// The default font key used when a text layer has none set.
  static const String defaultKey = 'Roboto';

  /// Ordered list of selectable fonts. Add more by extending this map.
  static final Map<String, TextStyle Function()> _builders = {
    'Roboto': GoogleFonts.roboto,
    'Lato': GoogleFonts.lato,
    'Montserrat': GoogleFonts.montserrat,
    'Oswald': GoogleFonts.oswald,
    'Bebas Neue': GoogleFonts.bebasNeue,
    'Poppins': GoogleFonts.poppins,
    'Playfair Display': GoogleFonts.playfairDisplay,
    'Anton': GoogleFonts.anton,
    'Pacifico': GoogleFonts.pacifico,
    'Cinzel': GoogleFonts.cinzel,
    'Orbitron': GoogleFonts.orbitron,
    'Press Start 2P': GoogleFonts.pressStart2p,
  };

  static List<String> get keys => _builders.keys.toList();

  static bool contains(String key) => _builders.containsKey(key);

  static String normalize(String? key) =>
      (key != null && contains(key)) ? key : defaultKey;

  /// A [TextStyle] for the given font key, used both for UI previews and to
  /// trigger the font load. Safe to call with an unknown key (falls back).
  static TextStyle style(String? key, {TextStyle? base}) {
    final builder = _builders[normalize(key)]!;
    return base == null ? builder() : builder().merge(base);
  }

  /// The registered family name for [key], for use in a low-level
  /// `ui.TextStyle`. Returns null if the font hasn't loaded yet.
  static String? familyOf(String? key) => style(key).fontFamily;

  /// Ensures every catalog font is loaded so the canvas can paint with them.
  /// Call once during app/editor startup.
  static Future<void> preloadAll() async {
    for (final builder in _builders.values) {
      // Accessing the style schedules the font load via the GoogleFonts cache.
      builder();
    }
    await GoogleFonts.pendingFonts();
  }

  /// Ensures a single font is loaded before it is needed for painting.
  static Future<void> ensureLoaded(String? key) async {
    style(key);
    await GoogleFonts.pendingFonts();
  }
}
