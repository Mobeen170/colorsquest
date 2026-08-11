import 'package:flutter/material.dart';

/// All Coloriboo brand colors live here.
///
/// Screens should use these instead of writing raw hex values.
class AppColors {
  // This class only holds constants, so it is never created.
  const AppColors._();

  static const Color bubbleSky = Color(0xFFEAF9FF);
  static const Color booBlue = Color(0xFF58C9F5);
  static const Color bubblePurple = Color(0xFF8B7CFF);
  static const Color bubblePink = Color(0xFFFF83C6);
  static const Color bubbleMint = Color(0xFF6FE3BC);
  static const Color sunnyPop = Color(0xFFFFD965);
  static const Color darkInk = Color(0xFF26324A);
  static const Color softInk = Color(0xFF64748B);
  static const Color white = Color(0xFFFFFFFF);
}

/// Builds the single ThemeData used by the whole app.
class AppTheme {
  // This class only holds the theme builder, so it is never created.
  const AppTheme._();

  /// Coloriboo's light, airy theme.
  static ThemeData light() {
    // Start from Boo Blue, then force the exact brand colors so they are not
    // shifted by Material's automatic color generation.
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.booBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.booBlue,
          onPrimary: AppColors.white,
          secondary: AppColors.bubblePurple,
          onSecondary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.darkInk,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bubbleSky,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.booBlue,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),

      // Big, round, bubbly buttons that are easy for small hands to tap.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.booBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.booBlue,
          side: const BorderSide(color: AppColors.booBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // Dark Ink for normal text, Soft Ink for quieter supporting text.
      textTheme: ThemeData.light().textTheme
          .apply(bodyColor: AppColors.darkInk, displayColor: AppColors.darkInk)
          .copyWith(
            bodySmall: const TextStyle(color: AppColors.softInk),
            labelSmall: const TextStyle(color: AppColors.softInk),
          ),
    );
  }
}
