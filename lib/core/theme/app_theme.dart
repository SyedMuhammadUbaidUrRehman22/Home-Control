import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C5CE7); // futuristic violet
  static const Color secondary = Color(0xFFFFB86B); // warm amber
  static const Color background = Color(0xFFFFF7EF); // warm cream
  static const Color card = Color(0xFFFFFCF8);
  static const Color darkPanel = Color(0xFF2D314A);
  static const Color mutedText = Color(0xFF8D8797);
  static const Color activeGreen = Color(0xFF33D69F);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: card,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeGreen;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeGreen.withOpacity(0.35);
          }
          return Colors.grey.shade300;
        }),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF27233A),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF27233A),
        ),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF3D3850)),
        bodySmall: TextStyle(fontSize: 11, color: mutedText),
      ),
    );
  }
}
