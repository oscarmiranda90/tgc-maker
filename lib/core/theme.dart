import 'package:flutter/material.dart';

class TgcTheme {
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF12121A);
  static const _surfaceVariant = Color(0xFF1C1C28);
  static const _primary = Colors.white;
  static const _accent = Color(0xFF7C6AF7);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          surface: _surface,
          primary: _primary,
          secondary: _accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
          ),
        ),
        cardColor: _surface,
        dividerColor: Colors.white12,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
          ),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 13),
          labelSmall: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: _accent,
          thumbColor: Colors.white,
          inactiveTrackColor: Colors.white12,
          overlayColor: Colors.white10,
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
        useMaterial3: true,
      );

  static const cardSurface = _surfaceVariant;
}
