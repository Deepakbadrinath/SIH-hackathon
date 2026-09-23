import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AccessibleTheme {
  // WCAG AAA Accessible Color Palette (High-Contrast & Elderly-Friendly)
  static const Color primaryBlue = Color(0xFF0F3D78); // Deep calming blue (>9:1 contrast against white)
  static const Color primaryBlueLight = Color(0xFFEBF3FC);
  static const Color accentGold = Color(0xFFB45309); // High-contrast amber/gold
  static const Color backgroundLight = Color(0xFFF8FAFC); // Off-white, soft on aging retinas
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFF94A3B8); // High contrast border for cards
  static const Color textDark = Color(0xFF0F172A); // High contrast near-black (15:1 ratio)
  static const Color textMuted = Color(0xFF334155); // Accessible secondary text (>7:1 ratio)
  static const Color successGreen = Color(0xFF166534); // Deep accessible green
  static const Color successGreenLight = Color(0xFFDCFCE7);
  static const Color warningOrange = Color(0xFF9A3412); // Deep accessible orange
  static const Color warningOrangeLight = Color(0xFFFFEDD5);
  static const Color errorRed = Color(0xFF991B1B); // Deep accessible red
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // High-Contrast Dark Mode Tokens (WCAG AAA compliant: >12:1 ratios)
  static const Color darkBackground = Color(0xFF000000); // True pitch black for maximum OLED contrast
  static const Color darkSurface = Color(0xFF18181B); // High contrast dark zinc
  static const Color darkSurfaceVariant = Color(0xFF27272A);
  static const Color darkBorder = Color(0xFFFACC15); // Bright accessible amber border
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure white on black (21:1)
  static const Color darkTextSecondary = Color(0xFFF4F4F5);
  static const Color darkAccentGold = Color(0xFFFACC15); // Vibrant yellow/amber
  static const Color darkSuccessGreen = Color(0xFF4ADE80);
  static const Color darkErrorRed = Color(0xFFF87171);

  /// Universal font fallback sequence supporting:
  /// - Chinese (PingFang SC, Microsoft YaHei, Noto Sans SC)
  /// - Japanese (Hiragino Sans, Yu Gothic, Noto Sans JP)
  /// - Korean (Apple SD Gothic Neo, Malgun Gothic, Noto Sans KR)
  /// - Arabic (Noto Sans Arabic, Segoe UI, Geeza Pro)
  /// - Indic scripts (Noto Sans Devanagari, Bengali, Tamil, Telugu, Kannada, Malayalam, Gurmukhi, Odia)
  static const List<String> fontFamilyFallback = [
    'Noto Sans',
    'Roboto',
    'PingFang SC',
    'Hiragino Sans',
    'Apple SD Gothic Neo',
    'Microsoft YaHei',
    'Yu Gothic',
    'Malgun Gothic',
    'Noto Sans CJK SC',
    'Noto Sans CJK JP',
    'Noto Sans CJK KR',
    'Noto Sans Arabic',
    'Noto Sans Devanagari',
    'Noto Sans Bengali',
    'sans-serif',
  ];

  static ThemeData getLightTheme({double fontScale = 1.0}) {
    final double baseDisplay = AppConstants.minDisplayFontSize * fontScale;
    final double baseHeading = AppConstants.minHeadingFontSize * fontScale;
    final double baseBody = AppConstants.minBodyFontSize * fontScale;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentGold,
        surface: surfaceWhite,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: baseDisplay,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: 0.5,
          height: 1.3,
          fontFamilyFallback: fontFamilyFallback,
        ),
        headlineMedium: TextStyle(
          fontSize: baseHeading,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: 0.25,
          height: 1.3,
          fontFamilyFallback: fontFamilyFallback,
        ),
        titleLarge: TextStyle(
          fontSize: (baseHeading - 4).clamp(22.0, 36.0),
          fontWeight: FontWeight.bold,
          color: textDark,
          height: 1.35,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyLarge: TextStyle(
          fontSize: baseBody,
          fontWeight: FontWeight.w600,
          color: textDark,
          height: 1.5,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: (baseBody - 2).clamp(18.0, 30.0),
          fontWeight: FontWeight.w500,
          color: textMuted,
          height: 1.5,
          fontFamilyFallback: fontFamilyFallback,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64.0, AppConstants.minTouchTargetSize + 8)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primaryBlue.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF134C94); // subtly brighter navy on hover
            }
            return primaryBlue;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white70;
            }
            return Colors.white;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0.0;
            if (states.contains(WidgetState.pressed)) return 1.5;
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 6.0;
            return 3.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x330F3D78)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.16);
            if (states.contains(WidgetState.hovered)) return Colors.white.withValues(alpha: 0.08);
            return null;
          }),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          animationDuration: const Duration(milliseconds: 180),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: baseBody, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64.0, AppConstants.minTouchTargetSize + 8)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primaryBlue.withValues(alpha: 0.38);
            }
            return primaryBlue;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return Colors.transparent;
            if (states.contains(WidgetState.pressed)) return primaryBlue.withValues(alpha: 0.12);
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return primaryBlue.withValues(alpha: 0.06);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 2.0;
            if (states.contains(WidgetState.pressed)) return 0.5;
            return 0.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x220F3D78)),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: primaryBlue.withValues(alpha: 0.38), width: 2.0);
            }
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(0xFF134C94), width: 2.5);
            }
            return const BorderSide(color: primaryBlue, width: 2.5);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return primaryBlue.withValues(alpha: 0.14);
            if (states.contains(WidgetState.hovered)) return primaryBlue.withValues(alpha: 0.06);
            return null;
          }),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          animationDuration: const Duration(milliseconds: 180),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: baseBody, fontWeight: FontWeight.bold, color: primaryBlue),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return primaryBlue.withValues(alpha: 0.16);
            if (states.contains(WidgetState.hovered)) return primaryBlue.withValues(alpha: 0.08);
            return null;
          }),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return primaryBlue.withValues(alpha: 0.16);
            if (states.contains(WidgetState.hovered)) return primaryBlue.withValues(alpha: 0.08);
            return null;
          }),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        color: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderLight, width: 1.8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: cardBorderLight, width: 2.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundLight,
        selectedColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: cardBorderLight, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorderLight, width: 1.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: baseHeading,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
    );
  }

  static ThemeData getHighContrastTheme({double fontScale = 1.0}) {
    final double baseDisplay = (AppConstants.minDisplayFontSize + 2) * fontScale;
    final double baseHeading = (AppConstants.minHeadingFontSize + 2) * fontScale;
    final double baseBody = (AppConstants.minBodyFontSize + 2) * fontScale;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkAccentGold,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkAccentGold,
        secondary: Color(0xFF38BDF8),
        surface: darkSurface,
        error: darkErrorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkTextPrimary,
        onError: Colors.black,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: baseDisplay,
          fontWeight: FontWeight.w900,
          color: darkTextPrimary,
          height: 1.3,
          fontFamilyFallback: fontFamilyFallback,
        ),
        headlineMedium: TextStyle(
          fontSize: baseHeading,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
          height: 1.3,
          fontFamilyFallback: fontFamilyFallback,
        ),
        titleLarge: TextStyle(
          fontSize: (baseHeading - 4).clamp(24.0, 40.0),
          fontWeight: FontWeight.bold,
          color: darkAccentGold,
          height: 1.35,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyLarge: TextStyle(
          fontSize: baseBody,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          height: 1.5,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyMedium: TextStyle(
          fontSize: (baseBody - 2).clamp(20.0, 32.0),
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
          height: 1.5,
          fontFamilyFallback: fontFamilyFallback,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64.0, AppConstants.minTouchTargetSize + 12)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return darkAccentGold.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFFDE047); // brighter amber/yellow on hover
            }
            return darkAccentGold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.black54;
            }
            return Colors.black;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0.0;
            if (states.contains(WidgetState.pressed)) return 2.0;
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 8.0;
            return 4.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x66FACC15)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.black.withValues(alpha: 0.20);
            if (states.contains(WidgetState.hovered)) return Colors.black.withValues(alpha: 0.08);
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return const BorderSide(color: Colors.white, width: 3.0);
            }
            return const BorderSide(color: Colors.white, width: 2.5);
          }),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          animationDuration: const Duration(milliseconds: 180),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: baseBody, fontWeight: FontWeight.w900),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64.0, AppConstants.minTouchTargetSize + 12)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return darkAccentGold.withValues(alpha: 0.38);
            }
            return darkAccentGold;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return Colors.transparent;
            if (states.contains(WidgetState.pressed)) return darkAccentGold.withValues(alpha: 0.20);
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return darkAccentGold.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 3.0;
            if (states.contains(WidgetState.pressed)) return 1.0;
            return 0.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x44FACC15)),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: darkAccentGold.withValues(alpha: 0.38), width: 2.5);
            }
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(0xFFFDE047), width: 3.5);
            }
            return const BorderSide(color: darkAccentGold, width: 3.0);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return darkAccentGold.withValues(alpha: 0.20);
            if (states.contains(WidgetState.hovered)) return darkAccentGold.withValues(alpha: 0.10);
            return null;
          }),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          animationDuration: const Duration(milliseconds: 180),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: baseBody, fontWeight: FontWeight.w900, color: darkAccentGold),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return darkAccentGold.withValues(alpha: 0.20);
            if (states.contains(WidgetState.hovered)) return darkAccentGold.withValues(alpha: 0.10);
            return null;
          }),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;
            return SystemMouseCursors.click;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return darkAccentGold.withValues(alpha: 0.20);
            if (states.contains(WidgetState.hovered)) return darkAccentGold.withValues(alpha: 0.10);
            return null;
          }),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 2.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder, width: 3.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        selectedColor: darkAccentGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: darkBorder, width: 2.0),
        ),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkAccentGold, width: 3.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkErrorRed, width: 2.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: baseHeading,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
    );
  }
}
