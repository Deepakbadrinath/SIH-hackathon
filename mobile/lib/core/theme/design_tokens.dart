import 'package:flutter/material.dart';

/// SmritiSetu Coherent Design System Tokens
///
/// Tailored for healthcare-adjacent cognitive accessibility, elderly ease-of-use,
/// and caregiver clarity. Strictly adheres to WCAG AAA contrast principles
/// (>7:1 body, >4.5:1 large text) with zero generic AI-dashboard tropes.
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Semantic layout insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
  static const EdgeInsets cardInnerPadding = EdgeInsets.all(18.0);
  static const EdgeInsets cardInnerPaddingCompact = EdgeInsets.all(14.0);
}

class AppRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static final BorderRadius smBorderRadius = BorderRadius.circular(sm);
  static final BorderRadius mdBorderRadius = BorderRadius.circular(md);
  static final BorderRadius lgBorderRadius = BorderRadius.circular(lg);
  static final BorderRadius xlBorderRadius = BorderRadius.circular(xl);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(pill);
}

class AppShadows {
  /// Calm, subtle ambient shadow for light mode cards (zero harsh glassmorphism)
  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% opacity slate
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x050F172A), // 2% opacity slate
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Elevated shadow for prominent action buttons and floating modals
  static const List<BoxShadow> elevatedButton = [
    BoxShadow(
      color: Color(0x140F3D78), // 8% deep navy
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Dark mode subtle ambient glow/shadow
  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

class AppColors {
  // Light Mode - Clinical & Calming Palette
  static const Color primaryNavy = Color(0xFF0F3D78);       // High-contrast deep medical navy (>9:1)
  static const Color primaryNavyLight = Color(0xFFEBF3FC);  // Tinted soft blue container
  static const Color secondaryAmber = Color(0xFFB45309);    // High-contrast warning/due amber
  static const Color secondaryAmberLight = Color(0xFFFEF3C7);
  static const Color clinicalJade = Color(0xFF15803D);      // Reassuring medical green
  static const Color clinicalJadeLight = Color(0xFFDCFCE7);
  static const Color criticalRed = Color(0xFFB91C1C);       // Medical alert crimson
  static const Color criticalRedLight = Color(0xFFFEE2E2);

  static const Color backgroundLight = Color(0xFFF8FAFC);   // Soft off-white, reduces retina fatigue
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);     // Neutral slate container
  static const Color borderSubtle = Color(0xFFCBD5E1);      // Crisp 1.5px border
  static const Color borderStrong = Color(0xFF94A3B8);      // High-visibility border

  static const Color textPrimary = Color(0xFF0F172A);       // Near-black (>15:1 contrast)
  static const Color textSecondary = Color(0xFF334155);     // Dark slate (>7:1 contrast)
  static const Color textMuted = Color(0xFF64748B);         // Caption text (>4.5:1 contrast)

  // Dark Mode - High-Contrast OLED Accessible Palette
  static const Color darkBackground = Color(0xFF000000);    // True black for maximum OLED battery & contrast
  static const Color darkSurface = Color(0xFF18181B);       // Zinc 900
  static const Color darkSurfaceSubtle = Color(0xFF27272A); // Zinc 800
  static const Color darkBorder = Color(0xFFFACC15);        // Accessible bright amber border (WCAG AAA)
  static const Color darkBorderSubtle = Color(0xFF3F3F46);  // Zinc 700

  static const Color darkTextPrimary = Color(0xFFFFFFFF);   // Pure white on black (21:1)
  static const Color darkTextSecondary = Color(0xFFF4F4F5); // Crisp zinc 100
  static const Color darkTextMuted = Color(0xFFA1A1AA);     // Zinc 400

  static const Color darkJade = Color(0xFF4ADE80);
  static const Color darkAmber = Color(0xFFFACC15);
  static const Color darkRed = Color(0xFFF87171);
}

class AppBreakpoints {
  /// Maximum content width for tablets and desktop viewports
  static const double maxContentWidth = 680.0;
  static const double compactPhoneWidth = 380.0;
}
