import 'package:flutter/material.dart';

import 'app_theme_builder.dart';
import 'app_tokens.dart';

// Warm Paper Scholar - from Stitch DESIGN.md. Colours are Stitch's,
// NOT newly selected here. See stitch-reference/warm_paper_scholar/DESIGN.md
// FONT: Hind Siliguri (OFL 1.1, fonts/ + pubspec.yaml) is the
// app-wide font since 2026-11-05 (see app_text_theme.dart); it used
// to be applied by hand on the answer screens only.
// THEME: light()/dark() are built by buildAppTheme() in
// app_theme_builder.dart (one builder for both modes). This file
// keeps the brand colours, subject colours, gradients and card style.
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
        color: dark ? DarkPalette.surface : card,
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

  static ThemeData light() => buildAppTheme(dark: false);
  static ThemeData dark() => buildAppTheme(dark: true);
}
