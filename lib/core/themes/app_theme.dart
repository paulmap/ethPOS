import 'package:flutter/material.dart';
import 'colors.dart';

/// Neutral grotesque with tabular numerals. Add Archivo to pubspec fonts,
/// or drop `fontFamily` to fall back to the platform sans.
const String kFontFamily = 'Archivo';

class AppTheme {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, fontFamily: kFontFamily);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.34,
          color: AppColors.ink,
        ),
      ),
      iconTheme: const IconThemeData(size: 20, color: AppColors.ink),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            headlineSmall: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
            titleMedium: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.15,
            ),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
            bodySmall: TextStyle(fontSize: 12, color: AppColors.placeholder),
            labelSmall: TextStyle(
              fontSize: 10,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedLight,
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(60), // one-handed hit target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.19,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.hairlineStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.hairlineStrong),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Shorthand for money and counts, which must never shift width.
const TextStyle kNumeric = TextStyle(fontFeatures: AppTheme.tabular);
