import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Premium Golden/Amber Palette
  static const Color primaryGold = Color(0xFFFFB74D); // Rich Amber/Gold
  static const Color accentGold = Color(0xFFFFD54F); // Lighter Amber
  static const Color darkGold = Color(0xFFF57C00); // Deep Orange/Gold for contrast
  
  static const Color backgroundLight = Color(0xFFF8F9FA); // Soft off-white
  static const Color backgroundDark = Color(0xFF121212); // Deep Charcoal
  
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark Grey
  
  static const Color textLight = Color(0xFF212121); // Almost Black
  static const Color textDark = Color(0xFFEEEEEE); // Off-white
  static const Color textGrey = Color(0xFF757575); // Subtitle Grey
  
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
}

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryGold,
    secondary: AppColors.accentGold,
    surface: AppColors.surfaceLight,
    background: AppColors.backgroundLight,
    onPrimary: AppColors.textLight,
    onSecondary: AppColors.textLight,
    onSurface: AppColors.textLight,
    onBackground: AppColors.textLight,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.backgroundLight,
  cardTheme: CardThemeData(
    color: AppColors.surfaceLight,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surfaceLight,
    foregroundColor: AppColors.textLight,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    titleTextStyle: GoogleFonts.outfit(
      color: AppColors.textLight,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.bold),
    headlineMedium: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.outfit(color: AppColors.textLight),
    bodyMedium: GoogleFonts.outfit(color: AppColors.textLight),
    labelLarge: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.w600),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.textLight,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryGold,
    secondary: AppColors.accentGold,
    surface: AppColors.surfaceDark,
    background: AppColors.backgroundDark,
    onPrimary: AppColors.textLight,
    onSecondary: AppColors.textLight,
    onSurface: AppColors.textDark,
    onBackground: AppColors.textDark,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.backgroundDark,
  cardTheme: CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textDark,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    titleTextStyle: GoogleFonts.outfit(
      color: AppColors.textDark,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold),
    headlineMedium: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.outfit(color: AppColors.textDark),
    bodyMedium: GoogleFonts.outfit(color: AppColors.textDark),
    labelLarge: GoogleFonts.outfit(color: AppColors.textLight, fontWeight: FontWeight.w600),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.textLight,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
    ),
  ),
);
