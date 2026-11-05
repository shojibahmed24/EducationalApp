import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language toggle: bn / en. Page strings live in lib/l10n/pages/
// (one file per page, e.g. login_strings.dart), each with bn + en maps.
// RULE: when you build a page, you write its strings file at the same time.
// Never build a page without its strings, never do all pages' strings later.
// The choice is persisted (ys_language) and restored at splash, so a
// language switch in Settings is LIVE app-wide and survives a restart.
final ValueNotifier<Locale> languageNotifier =
    ValueNotifier<Locale>(const Locale('bn'));

bool get isBangla => languageNotifier.value.languageCode == 'bn';

void setLanguage(String code) {
  languageNotifier.value = Locale(code);
  SharedPreferences.getInstance().then(
    (prefs) => prefs.setString('ys_language', code),
  );
}

Future<void> restoreLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('ys_language');
  if (code == 'bn') {
    languageNotifier.value = const Locale('bn');
  } else if (code == 'en') {
    languageNotifier.value = const Locale('en');
  }
}
