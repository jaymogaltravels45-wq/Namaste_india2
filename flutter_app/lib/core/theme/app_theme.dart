import 'package:flutter/material.dart';

/// Namaste India — Premium design system (2026).
///
/// Deep-navy + gold "premium India" language layered on the brand blue.
/// All screens should use these tokens instead of hard-coded colors.
class AppTheme {
  // ── Brand ──────────────────────────────────────────────
  static const primary = Color(0xFF1565C0);
  static const primaryColor = Color(0xFF1565C0); // alias
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryDeep = Color(0xFF0A2A5E);

  // ── Premium accents ────────────────────────────────────
  static const gold = Color(0xFFF5B301);
  static const goldDeep = Color(0xFFD49400);
  static const goldSoft = Color(0xFFFFF6DE);
  static const navy = Color(0xFF0B1B33);
  static const navySoft = Color(0xFF12294D);

  // ── Background / surface ───────────────────────────────
  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFEDF1F8);

  // ── Text ───────────────────────────────────────────────
  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);

  // ── Border ─────────────────────────────────────────────
  static const border = Color(0xFFE4E9F2);
  static const borderStrong = Color(0xFFD0D8E8);

  // ── Status ─────────────────────────────────────────────
  static const success = Color(0xFF12B76A);
  static const successSoft = Color(0xFFE7F8EF);
  static const error = Color(0xFFF04438);
  static const errorSoft = Color(0xFFFDECEA);
  static const warning = Color(0xFFF79009);
  static const warningSoft = Color(0xFFFFF3E0);
  static const info = Color(0xFF2E90FA);
  static const infoSoft = Color(0xFFEFF6FF);

  // ── Gradients ──────────────────────────────────────────
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0A2A5E), Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const navyGradient = LinearGradient(
    colors: [Color(0xFF0B1B33), Color(0xFF12294D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF5B301), Color(0xFFD49400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const blueGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const successGradient = LinearGradient(
    colors: [Color(0xFF12B76A), Color(0xFF0E8F52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Radii ──────────────────────────────────────────────
  static const rSm = 10.0;
  static const rMd = 16.0;
  static const rLg = 22.0;
  static const rXl = 28.0;

  // ── Shadows ────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: const Color(0xFF0B1B33).withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: const Color(0xFF0B1B33).withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: const Color(0xFF0B1B33).withOpacity(0.14),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
  static List<BoxShadow> get shadowGold => [
        BoxShadow(
          color: const Color(0xFFF5B301).withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
  static List<BoxShadow> get shadowBlue => [
        BoxShadow(
          color: const Color(0xFF1565C0).withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── ThemeData ──────────────────────────────────────────
  static final light = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textTertiary, fontSize: 15),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: textPrimary,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
      bodyMedium: TextStyle(
          fontSize: 14, color: textSecondary, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
  );
}
