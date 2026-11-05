import 'package:flutter/material.dart';

// Warm Paper Scholar - from Stitch DESIGN.md. Colours are Stitch's,
// NOT newly selected here. See stitch-reference/warm_paper_scholar/DESIGN.md
// FONT (C4 resolved 2026-10-29): Hind Siliguri OFL 1.1 .ttf files
// now live in fonts/ and are registered in pubspec.yaml. The
// app-wide default fontFamily is deliberately UNCHANGED here —
// the answer screen's renderer passes fontFamily 'HindSiliguri'
// explicitly for Bangla text only (minimal change, locked design).
class AppTheme {
  static const paper = Color(0xFFFBF6EC);
  static const card = Color(0xFFFFFDF8);
  static const ink = Color(0xFF26231F);
  static const inkSecondary = Color(0xFF5E5850);
  static const inkMuted = Color(0xFF9C9388);
  static const primary = Color(0xFF2F6FED);
  static const primaryDark = Color(0xFF1E4FBF);
  static const secondary = Color(0xFF6D5BD0);
  static const amber = Color(0xFFF5A524);
  static const success = Color(0xFF2E9E6B);
  static const error = Color(0xFFE5534B);
  // Home "continue learning" hero card (batch 2, item 2): SOLID
  // fills, never a translucent wash. Light = Stitch "Primary Soft
  // Tint" #DCEBFF with foreground #1A4AA6; dark = primaryDark
  // #1E4FBF with white text.
  static const heroTint = Color(0xFFDCEBFF);
  static const heroTintOn = Color(0xFF1A4AA6);

  // UI palette (গ) warm + multi-subject (2026-10-31, UI-only).
  // Warm cream base stays (#FBF6EC, never pure white as a study
  // background). Existing values above are unchanged. Subject
  // colours: math blue, science green, Bangla orange-red,
  // English purple, BGS teal, ICT cyan-blue, religion deep gold.
  // Unknown subject ids fall back to neutral slate (not a guess
  // at a subject colour). Dark pairs are deeper, less saturated.
  static const subjectColors = <String, Color>{
    'math': Color(0xFF2F6FED),
    'science': Color(0xFF2E9E6B),
    'bangla': Color(0xFFE86A2C),
    'english': Color(0xFF6D5BD0),
    'bgs': Color(0xFF0E8A8A),
    'ict': Color(0xFF0891B2),
    'religion': Color(0xFFB45309),
  };
  static const subjectColorsDark = <String, Color>{
    'math': Color(0xFF60A5FA),
    'science': Color(0xFF4ADE80),
    'bangla': Color(0xFFFB923C),
    'english': Color(0xFFA78BFA),
    'bgs': Color(0xFF2DD4BF),
    'ict': Color(0xFF38BDF8),
    'religion': Color(0xFFFBBF24),
  };
  static Color subjectColorFor(String id, {bool dark = false}) =>
      (dark ? subjectColorsDark : subjectColors)[id] ??
      (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
  // Gradients use deep stops so white text stays WCAG AA on
  // them (light list) and deep dark stops (dark list). They are
  // for headers/buttons/cards only, never behind large text.
  static const heroGradient =
      LinearGradient(colors: [Color(0xFF1E4FBF), Color(0xFF5B4BC4)]);
  static const heroGradientDark =
      LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)]);
  static const premiumGradient =
      LinearGradient(colors: [Color(0xFF92400E), Color(0xFF5B4BC4)]);
  static const premiumGradientDark =
      LinearGradient(colors: [Color(0xFF78350F), Color(0xFF4C1D95)]);
  static const statGradients = [
    LinearGradient(colors: [Color(0xFF1E4FBF), Color(0xFF5B4BC4)]),
    LinearGradient(colors: [Color(0xFF1E7A52), Color(0xFF0E7A7A)]),
    LinearGradient(colors: [Color(0xFFC2410C), Color(0xFFBE185D)]),
  ];
  static const statGradientsDark = [
    LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)]),
    LinearGradient(colors: [Color(0xFF14532D), Color(0xFF134E4A)]),
    LinearGradient(colors: [Color(0xFF7C2D12), Color(0xFF831843)]),
  ];
  // ONE soft card style for the whole app: softer radius, tint
  // border, one soft shadow. Accent is the card-type colour.
  static BoxDecoration softCardDecoration({
    Color? accent,
    required bool dark,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: dark ? const Color(0xFF334155) : card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: (accent ?? primary).withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        // H5 FIX: secondaryContainer/onSecondaryContainer were never
        // defined, so Flutter derived the container from purple
        // secondary and the banner's dark-grey text was unreadable
        // (~1.36:1 on the purple itself). Explicit pair below:
        // dark purple 0xFF21005D on pale lavender 0xFFEADDFF
        // = 13.32:1 (WCAG AAA, needs >= 4.5:1 for normal text).
        secondaryContainer: Color(0xFFEADDFF),
        onSecondaryContainer: Color(0xFF21005D),
        error: error,
        surface: card,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          height: 1.58,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.75, color: ink),
        bodyMedium: TextStyle(fontSize: 15, height: 1.73, color: ink),
        bodySmall: TextStyle(fontSize: 13, height: 1.69, color: inkSecondary),
        labelLarge: TextStyle(
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      // Small link/button text (TextButton) must clear 4.5:1 on
      // the warm paper: primaryDark #1E4FBF does (6.66:1), while
      // the old default primary #2F6FED only reached 4.22:1.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryDark),
      ),
      cardTheme: CardThemeData(
        // Card literal 0xFFFFFDF8 is already solid (alpha FF);
        // the old 0.85 alpha override only muddied it to
        // #FEFCF6, so the solid card is used directly. Ink on
        // it is 15.39:1, still passing.
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E293B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        secondary: secondary,
        // H5 FIX (dark): explicit pair, same reason as light.
        // Pale lavender 0xFFE8DEF8 on dark grey-purple 0xFF4A4458
        // = 7.19:1 (WCAG AAA, needs >= 4.5:1 for normal text).
        secondaryContainer: Color(0xFF4A4458),
        onSecondaryContainer: Color(0xFFE8DEF8),
        surface: Color(0xFF334155),
        // Light-family text on the dark surface (9.45:1);
        // lesson/chat/guide bodies resolve to this instead of
        // the forced light-mode ink, which was 1.51:1 here.
        onSurface: Color(0xFFF1F5F9),
      ),
      // Dark textTheme (previously absent, so dark screens fell
      // back to unspecified colours): same sizes as light, with
      // light-family colours throughout.
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF8FAFC),
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          height: 1.58,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF8FAFC),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF8FAFC),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF1F5F9),
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 1.75,
          color: Color(0xFFF1F5F9),
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.73,
          color: Color(0xFFF1F5F9),
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          height: 1.69,
          color: Color(0xFFCBD5E1),
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF1F5F9),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF334155),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
