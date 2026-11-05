import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global theme mode, driven by SettingsScreen (night -> dark, day/sepia
// -> light; AppTheme has no sepia theme, so sepia falls back to light).
// Theme + font scale are persisted (ys_theme, ys_font_scale) and
// restored at splash, so Settings choices are LIVE and survive restart.
// Sepia fallback is stated in the Settings UI text, not hidden.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

// REVIEW FIX: font size chosen in Settings, applied app-wide in app.dart
// via MediaQuery textScaler. 1.0 = normal, 0.85 = small, 1.25 = large.
final ValueNotifier<double> fontScaleNotifier =
    ValueNotifier<double>(1.0);

void persistTheme(String name) {
  SharedPreferences.getInstance().then(
    (prefs) => prefs.setString('ys_theme', name),
  );
}

void persistFontScale(double scale) {
  SharedPreferences.getInstance().then(
    (prefs) => prefs.setDouble('ys_font_scale', scale),
  );
}

Future<void> restoreAppearance() async {
  final prefs = await SharedPreferences.getInstance();
  final theme = prefs.getString('ys_theme');
  if (theme == 'night') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.light;
  }
  final scale = prefs.getDouble('ys_font_scale');
  if (scale != null && scale > 0) fontScaleNotifier.value = scale;
}
