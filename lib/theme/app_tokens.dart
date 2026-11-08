// Global design tokens (2026-11-05, UI-only): one spacing scale,
// one radius scale, and the supplemental palettes used by the
// shared theme builder. Brand colours stay in AppTheme; these are
// the layout scale plus the warm dark palette. Dark mode used to
// be cool slate (#1E293B) next to a warm cream light mode; it is
// now a warm brown-black so both modes feel like one app.
import 'package:flutter/material.dart';

/// Spacing scale (logical px). Use these instead of loose numbers.
class Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double huge = 32;
}

/// Corner radius scale. [xl] matches the app-wide Card radius (24)
/// and HomeDesign.cardRadius, so ripples always match the card.
class Rad {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 28;
}

/// Warm dark palette. Contrast (WCAG, computed): onSurface on
/// surface 13.4:1, onSurfaceMuted on surface 9.7:1, inputOutline on
/// surface 4.2:1 (needs 3:1 for UI borders).
class DarkPalette {
  static const background = Color(0xFF1C1814);
  static const backgroundTop = Color(0xFF27211B);
  static const surface = Color(0xFF2A241E);
  static const surfaceHigh = Color(0xFF342D26);
  static const outline = Color(0xFF4A4036);
  static const inputOutline = Color(0xFF8F8576);
  static const onSurface = Color(0xFFF5EFE6);
  static const onSurfaceMuted = Color(0xFFD6CDBF);
}

/// Light-mode supplemental tokens (the base cream/ink live in AppTheme).
class LightPalette {
  /// Top of the layered background gradient AND the AppBar colour,
  /// so the header band and the body gradient meet without a seam.
  static const backgroundTop = Color(0xFFE8F0FE);
  static const hairline = Color(0xFFE3DACB);
  static const inputOutline = Color(0xFF8C8478);
}
