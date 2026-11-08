// ONE theme builder for light + dark (2026-11-05, UI-only).
// Every screen inherits the same app bar, cards, buttons, inputs,
// chips, dialogs, sheets, snack bars and bottom nav from here, so
// no screen needs its own styling to look consistent. Before this,
// dark mode had no button/card-shape theme at all and light mode
// only styled one button. Brand colours/gradients stay in AppTheme.
//
// Contrast (WCAG, computed): white on primaryDark 7.2:1 (light
// buttons); #0B1220 on #60A5FA 7.4:1 (dark buttons); primaryDark on
// the app bar tint 6.3:1; input border on card 3.6:1 (light) and
// 4.2:1 (dark), both above the 3:1 needed for UI boundaries.
import 'package:flutter/material.dart';

import 'app_text_theme.dart';
import 'app_theme.dart';
import 'app_tokens.dart';

ThemeData buildAppTheme({required bool dark}) {
  final ink = dark ? DarkPalette.onSurface : AppTheme.ink;
  final muted = dark ? DarkPalette.onSurfaceMuted : AppTheme.inkSecondary;
  final surface = dark ? DarkPalette.surface : AppTheme.card;
  final background = dark ? DarkPalette.background : AppTheme.paper;
  final hairline = dark ? DarkPalette.outline : LightPalette.hairline;
  final inputOutline =
      dark ? DarkPalette.inputOutline : LightPalette.inputOutline;
  final link = dark ? const Color(0xFF60A5FA) : AppTheme.primaryDark;
  final onLink = dark ? const Color(0xFF0B1220) : Colors.white;
  final text = buildAppTextTheme(ink: ink, muted: muted);

  // H5 FIX (kept): secondaryContainer pairs are explicit. Light:
  // 0xFF21005D on 0xFFEADDFF = 13.32:1. Dark: 0xFFE8DEF8 on
  // 0xFF4A4458 = 7.19:1 (both WCAG AAA).
  final scheme = dark
      ? ColorScheme.dark(
          primary: const Color(0xFF60A5FA),
          secondary: AppTheme.secondary,
          secondaryContainer: const Color(0xFF4A4458),
          onSecondaryContainer: const Color(0xFFE8DEF8),
          surface: surface,
          onSurface: ink,
          outline: inputOutline,
          outlineVariant: hairline,
          surfaceTint: Colors.transparent,
        )
      : ColorScheme.light(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          secondaryContainer: const Color(0xFFEADDFF),
          onSecondaryContainer: const Color(0xFF21005D),
          error: AppTheme.error,
          surface: surface,
          onSurface: ink,
          outline: inputOutline,
          outlineVariant: hairline,
          surfaceTint: Colors.transparent,
        );

  final pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Rad.pill),
  );
  final actionStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    backgroundColor: link,
    foregroundColor: onLink,
    elevation: 0,
    textStyle: text.labelLarge,
    shape: pill,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: kAppFont,
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
    textTheme: text,
    dividerTheme: DividerThemeData(color: hairline, thickness: 1),
    // Header band uses the SAME colour as the top of AppBackground's
    // gradient, so the app bar and the body meet without a seam.
    appBarTheme: AppBarTheme(
      backgroundColor:
          dark ? DarkPalette.backgroundTop : LightPalette.backgroundTop,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.headlineMedium,
      iconTheme: IconThemeData(color: ink),
    ),
    // Card radius stays 24 (HomeDesign.cardRadius, InkWell ripples
    // use 24). Added: hairline border + one soft shadow, no tint.
    cardTheme: CardThemeData(
      color: surface,
      elevation: dark ? 0 : 1,
      shadowColor: const Color(0x33000000),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.xl),
        side: BorderSide(color: hairline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: actionStyle),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: link,
        foregroundColor: onLink,
        textStyle: text.labelLarge,
        shape: pill,
      ),
    ),
    // Outlined buttons were 40px tall next to 56px primary buttons
    // (quiz Prev/Next row). Same 56 height + pill shape now; the
    // width floor is finite so a Row without Expanded cannot break.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 56),
        foregroundColor: link,
        side: BorderSide(color: inputOutline),
        textStyle: text.labelLarge,
        shape: pill,
      ),
    ),
    // Small link/button text must clear 4.5:1 on the paper:
    // primaryDark does (6.66:1); the old primary only 4.22:1.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: link,
        minimumSize: const Size(64, 44),
      ),
    ),
    // Only `border` is set (not enabled/focused borders): screens
    // that pass their own InputDecoration.border keep it, and
    // Flutter derives the focused/error rings from whichever border
    // is in effect.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.bodyMedium?.copyWith(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        borderSide: BorderSide(color: inputOutline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      side: BorderSide(color: hairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      labelStyle: text.labelMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? DarkPalette.surfaceHigh : AppTheme.ink,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: dark ? DarkPalette.onSurface : Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.xl),
      ),
      titleTextStyle: text.headlineMedium,
      contentTextStyle: text.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surface,
      elevation: 8,
      selectedItemColor: link,
      unselectedItemColor: muted,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontFamily: kAppFont,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: kAppFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
