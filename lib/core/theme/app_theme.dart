// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Exact palette from bhaktapur_ar_redesign_v2.html ──────────────────────
  static const Color brick      = Color(0xFF7A2E1C); // --brick
  static const Color brick2     = Color(0xFFA33D28); // --brick2
  static const Color gold       = Color(0xFFC9A84C); // --gold
  static const Color gold2      = Color(0xFFE8C96A); // --gold2
  static const Color deep       = Color(0xFF14151C); // --deep  (body bg)
  static const Color surf       = Color(0xFF1E2028); // --surf
  static const Color surf2      = Color(0xFF272A35); // --surf2
  static const Color surf3      = Color(0xFF30333F); // --surf3
  static const Color smoke      = Color(0xFFF2EDE4); // --smoke
  static const Color ash        = Color(0xFF7A7D87); // --ash
  static const Color mist       = Color(0xFFB0B3BC); // --mist
  static const Color green      = Color(0xFF3DBF7A); // --green
  static const Color overlay    = Color(0xF50E0F14); // --overlay rgba(14,15,20,.96)
  static const Color border     = Color(0x12FFFFFF); // --border rgba(255,255,255,.07)

  // ── Aliases kept for backward-compat ──────────────────────────────────────
  static const Color brickDust      = brick;
  static const Color goldLeaf       = gold;
  static const Color deepSlate      = deep;
  static const Color smokeWhite     = smoke;
  static const Color ashGray        = ash;
  static const Color overlayDark    = overlay;
  static const Color successGreen   = green;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.deep,

    colorScheme: const ColorScheme.dark(
      primary:   AppColors.gold,
      secondary: AppColors.brick,
      surface:   AppColors.surf,
      onPrimary: AppColors.deep,
      onSurface: AppColors.smoke,
    ),

    textTheme: TextTheme(
      // Cinzel headings
      displayLarge: GoogleFonts.cinzel(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.smoke, letterSpacing: 1.2,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.smoke,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.smoke,
      ),
      // Lato body
      bodyLarge: GoogleFonts.lato(
        fontSize: 13, color: AppColors.smoke.withValues(alpha: 0.85), height: 1.65,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 11, color: AppColors.ash, height: 1.5,
      ),
      // Labels
      labelLarge: GoogleFonts.lato(
        fontSize: 13, color: AppColors.smoke,
        fontWeight: FontWeight.w700, letterSpacing: 2.5,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: 9, color: AppColors.gold,
        fontWeight: FontWeight.w700, letterSpacing: 2.0,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.cinzel(
        fontSize: 18, color: AppColors.smoke, fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.smoke),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surf,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
  );
}
