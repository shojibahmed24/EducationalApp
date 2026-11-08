// App-wide Bangla-first text theme (2026-11-05, UI-only).
// Hind Siliguri (SIL OFL 1.1, fonts/OFL.txt) is now the app-wide
// font. Before this it was applied by hand on a few answer screens
// only, so Home / Quiz / Practice / Settings fell back to the
// device font. Existing sizes and line-heights are UNCHANGED
// (they were tuned for Bangla conjuncts and the H4 overflow fix);
// only the missing title/label styles were added so every screen
// resolves to the same family. The family is also set on each
// style explicitly, so it never depends on ThemeData merging.
import 'package:flutter/material.dart';

const String kAppFont = 'HindSiliguri';

TextTheme buildAppTextTheme({required Color ink, required Color muted}) {
  TextStyle s(double size, double height, FontWeight w, Color c) =>
      TextStyle(
        fontFamily: kAppFont,
        fontSize: size,
        height: height,
        fontWeight: w,
        color: c,
      );
  return TextTheme(
    displayLarge: s(28, 1.5, FontWeight.w700, ink),
    headlineLarge: s(24, 1.58, FontWeight.w600, ink),
    headlineMedium: s(20, 1.6, FontWeight.w600, ink),
    titleLarge: s(18, 1.6, FontWeight.w600, ink),
    titleMedium: s(16, 1.6, FontWeight.w600, ink),
    titleSmall: s(14, 1.6, FontWeight.w600, ink),
    bodyLarge: s(17, 1.75, FontWeight.w400, ink),
    bodyMedium: s(15, 1.73, FontWeight.w400, ink),
    bodySmall: s(13, 1.69, FontWeight.w400, muted),
    labelLarge: s(15, 1.6, FontWeight.w600, ink),
    labelMedium: s(13, 1.5, FontWeight.w600, ink),
    labelSmall: s(12, 1.5, FontWeight.w500, muted),
  );
}
