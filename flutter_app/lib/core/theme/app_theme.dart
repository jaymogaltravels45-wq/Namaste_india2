import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const primary      = Color(0xFF1565C0);
  static const primaryColor = Color(0xFF1565C0); // alias

  // Background / surface
  static const background   = Color(0xFFF5F7FA);
  static const surface      = Color(0xFFFFFFFF);

  // Text
  static const textPrimary   = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);

  // Border
  static const border       = Color(0xFFE5E7EB);

  // Status colors
  static const success      = Color(0xFF10B981);
  static const error        = Color(0xFFEF4444);
  static const warning      = Color(0xFFF59E0B);

  static final light = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: background,
      surface: surface,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
  );
}
