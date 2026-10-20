import 'package:flutter/material.dart';

class NoteColors {
  NoteColors._();

  static const Map<String, Color?> colors = {
    'Default': null,
    'Red': Color(0xFFF28B82),
    'Pink': Color(0xFFF4A261),
    'Orange': Color(0xFFFBD75B),
    'Yellow': Color(0xFFFFF475),
    'Sage': Color(0xFFCCFF90),
    'Teal': Color(0xFFA8DAB5),
    'Blue': Color(0xFFCBF0F8),
    'DarkBlue': Color(0xFFAECBFA),
    'Purple': Color(0xFFD7AEFB),
    'Pink2': Color(0xFFFDCFE8),
  };

  static const List<String> colorNames = [
    'Default',
    'Red',
    'Pink',
    'Orange',
    'Yellow',
    'Sage',
    'Teal',
    'Blue',
    'DarkBlue',
    'Purple',
    'Pink2',
  ];

  static Color? colorFromHex(String? hex) {
    if (hex == null) return null;
    try {
      final cleaned = hex.replaceFirst('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return null;
    }
  }

  static String? hexFromColor(Color? color) {
    if (color == null) return null;
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static Color cardColor(String? hex, bool isDark) {
    if (hex == null) {
      return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    }
    final c = colorFromHex(hex);
    if (c == null) {
      return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    }
    return isDark ? _darkenColor(c, 0.3) : c;
  }

  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
