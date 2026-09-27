import 'package:flutter/material.dart';

class NexusColors {
  static const Color background = Color(0xFF0A0D14);
  static const Color surface = Color(0xFF121722);
  static const Color surfaceElevated = Color(0xFF181F2E);
  static const Color border = Color(0xFF222B3D);

  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryDark = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFF7C4DFF); // Deep Violet
  static const Color accent = Color(0xFF00E676); // Emerald Green

  static const Color textPrimary = Color(0xFFF0F4FC);
  static const Color textSecondary = Color(0xFF8E9BB5);
  static const Color textMuted = Color(0xFF5A6680);

  static const Color statusOnline = Color(0xFF00E676);
  static const Color statusOffline = Color(0xFFFF5252);
  static const Color statusWarning = Color(0xFFFFD600);

  static const Color cpuColor = Color(0xFF00E5FF);
  static const Color gpuColor = Color(0xFF76FF03);
  static const Color ramColor = Color(0xFFFF9100);
  static const Color diskColor = Color(0xFFE040FB);
  static const Color netColor = Color(0xFF2979FF);
}

class NexusTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NexusColors.background,
      primaryColor: NexusColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: NexusColors.primary,
        secondary: NexusColors.secondary,
        surface: NexusColors.surface,
      ),
      cardTheme: CardThemeData(
        color: NexusColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NexusColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NexusColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: NexusColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NexusColors.surface,
        selectedItemColor: NexusColors.primary,
        unselectedItemColor: NexusColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
