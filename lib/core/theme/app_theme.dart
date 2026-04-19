import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        secondary: AppColors.secondary,
        onSecondary: AppColors.foreground,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
      cardTheme: CardThemeData(
        color: AppColors.card,
        margin: EdgeInsets.zero,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerColor: AppColors.border,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
    );
  }
}
