// AI provider choice for written explanations (2026-11-04).
//
// Both providers run through the explain-question Edge Function
// (Mode GEN) — the app never calls a provider directly and never
// holds a key. This service only remembers WHICH provider the
// Edge should use, in SharedPreferences under 'ys_ai_provider'.
// 'openrouter' is the default and the only value that keeps the
// previous behaviour exactly; 'gemini' asks the Edge for its
// Gemini path (which needs the GEMINI_API_KEY Edge secret —
// set server-side, never here, never in the app).
// Unknown or unreadable values normalise to 'openrouter', so a
// bad preference can never break generation: the caller falls
// back to the proven OpenRouter path.
import 'package:shared_preferences/shared_preferences.dart';

class AiProviderService {
  static const String openRouter = 'openrouter';
  static const String gemini = 'gemini';
  static const String prefsKey = 'ys_ai_provider';

  String _normalize(String? value) =>
      value == gemini ? gemini : openRouter;

  /// Saved provider, or 'openrouter' when nothing is saved,
  /// the value is unknown, or prefs cannot be read (tests
  /// without a mock, for example — generation must not fail
  /// just because the preference read failed).
  Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _normalize(prefs.getString(prefsKey));
    } catch (_) {
      return openRouter;
    }
  }

  /// Persist immediately (Settings saves on tap, like language
  /// and theme — no separate Save step for this choice).
  Future<void> save(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, _normalize(provider));
    } catch (_) {
      // A failed preference write must not crash Settings;
      // the next load simply returns the previous default.
    }
  }
}

final aiProviderService = AiProviderService();
