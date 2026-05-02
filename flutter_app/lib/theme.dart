// ─── theme.dart ────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class AppTheme {
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFF0D080);
  static const Color teal = Color(0xFF1DA57A);
  static const Color tealLight = Color(0xFF52C4A0);
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color card = Color(0xFF141414);
  static const Color card2 = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFE8E6E0);
  static const Color textSecondary = Color(0xFFA0A09A);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: teal,
      surface: card,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card2,
      labelStyle: const TextStyle(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gold),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card2,
      selectedColor: gold.withOpacity(0.2),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      labelSmall: TextStyle(color: textSecondary, fontSize: 11),
    ),
  );
}

// ── Room Type Helpers ──────────────────────────────────────────────────────

class RoomTypeConfig {
  static const icons = {
    'single': Icons.single_bed,
    'double': Icons.bed,
    'suite': Icons.king_bed,
  };

  static const colors = {
    'single': Color(0xFF4A9FD4),
    'double': Color(0xFF1DA57A),
    'suite': Color(0xFFC9A84C),
  };

  static const labels = {
    'single': 'Single',
    'double': 'Double',
    'suite': 'Suite',
  };
}
