// App colors, sizes, text styles and the Material theme.
// Every value comes from the AgosUgnayan Figma file (v3 row), so screens never
// hard-code a color or size. To change the look of the whole app, edit here.

import 'package:flutter/material.dart';

/// Colors taken from the Figma v3 frames.
class AppColors {
  AppColors._();

  static const Color primary = Color(
    0xFF4A7F2C,
  ); // top bars, links, eyebrow text
  static const Color primaryDark = Color(0xFF2F5E1C); // main buttons, prices
  static const Color primaryLight = Color(
    0xFFEAF4E4,
  ); // chips, avatars, nav pill
  static const Color onPrimaryMuted = Color(0xFFDDEBD3); // subtitle on green
  static const Color background = Color(0xFFF1F2ED); // page background
  static const Color surface = Colors.white; // cards and inputs
  static const Color segmented = Color(0xFFECEAE4); // segmented control track
  static const Color border = Color(0xFFE4E2DA);
  static const Color text = Color(0xFF2B2118);
  static const Color textMuted = Color(0xFF7A7468);
  static const Color accent = Color(0xFFE07B2E); // badge counts
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerLight = Color(0xFFFBE9E7);
}

/// Spacing and corner radius values used across the app.
class AppSizes {
  AppSizes._();

  static const double pagePadding = 16;
  static const double sectionGap = 16;
  static const double fieldGap = 14;
  static const double labelGap = 6;
  static const double small = 8;

  static const double radiusCard = 14;
  static const double radiusButton = 12;
  static const double radiusInput = 10;
  static const double radiusChip = 10;
  static const double radiusSmallButton = 8;

  static const double minTapTarget = 48; // accessibility minimum
}

/// Font family names. The font files are in assets/fonts and listed in
/// pubspec.yaml under `fonts:`; the names here must match the `family:` there.
class AppFonts {
  AppFonts._();

  static const String body = 'Inter';
  static const String display = 'BarlowCondensed';
}

/// Text styles that Material's TextTheme doesn't cover.
class AppTextStyles {
  AppTextStyles._();

  /// Big uppercase page title, e.g. "HELLO, MANG PEDRO." (32 ExtraBold).
  static const TextStyle pageTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 34 / 32,
    color: AppColors.text,
  );

  /// Small green uppercase line above a page title, e.g. "LEON, ILOILO".
  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0.96,
    color: AppColors.primary,
  );

  /// "See all" style link next to a section heading.
  static const TextStyle link = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: AppColors.primary,
  );
}

/// Builds the app-wide [ThemeData] so buttons, inputs, cards and the bottom
/// navigation look like Figma without styling each widget by hand.
ThemeData buildAppTheme() {
  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusInput)),
    borderSide: BorderSide(color: AppColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primaryDark,
      secondary: AppColors.primary,
      error: AppColors.danger,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: 0.48,
        color: Colors.white,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusCard)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmallButton),
        ),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: AppColors.primaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusChip)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.textMuted,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
