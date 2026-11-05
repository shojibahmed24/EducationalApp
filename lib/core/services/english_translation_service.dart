// English → Bangla translator for the English reader (2026-11-03).
// The reader shows guide English (passages, questions, options,
// printed answers) even when the app UI is Bangla. This switch
// translates that content — the whole reader surface — into
// natural, accurate Bangla. It is NOT word-by-word: the prompt
// demands meaning-based, idiomatic Bangla, the way a good
// Bangla textbook would say it, with the original structure
// kept (line breaks, letter format, options kept separate by
// translating each field on its own).
//
// Transport reuses the existing AI path: openRouterClient.chatRaw
// (Edge Mode GEN, key server-side) — no new backend, no new key.
// Cache: in-memory first, then SharedPreferences, both keyed by
// a stable FNV-1a hash of the source text (Dart hashCode is NOT
// stable across runs, so it must never key the persisted cache).
// A repeat view therefore never calls the model twice.
// Cache version v2 (2026-11-03): prompt + script validation
// changed, so v1 entries are orphaned and every text is
// re-fetched once under the new prompt — a bad v1 translation
// cached on the phone must never keep showing.
// Failure is honest: translate() returns null and the caller
// shows the ORIGINAL English plus a note and a retry — never a
// blank area, never silently mixed partial output. A script-
// garbage output is a failure too: it is never cached.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'explanation_script_guard.dart';
import 'openrouter_client.dart';

/// The AI call behind translation; injected in tests so no model
/// or network is needed. Defaults to the shared OpenRouter client.
typedef TranslationAiCall = Future<GenResult> Function({
  required String systemPrompt,
  required String userPrompt,
});

/// Meaning-based Bangla translation prompt. The model must
/// rewrite sentences idiomatically, never word-by-word, and must
/// output ONLY the translation — no notes, no explanations, no
/// extra sentences — so the result can replace the source text
/// in place. Names of people and places are transliterated into
/// Bangla script, not translated for meaning.
/// Language level (user order 2026-11-03): simple, easy Bangla
/// a class 9 student understands — short sentences, common
/// everyday words, no difficult literary words. Script rule
/// (same order): Bangla script ONLY — never Chinese, Korean,
/// Japanese, Arabic, Hindi, or any other script, and never a
/// Latin word mixed into a Bangla sentence.
const String translationSystemPrompt =
    'You are an expert English-to-Bangla translator for '
    'Bangladeshi school students. Translate the given English '
    'text into natural, accurate, idiomatic Bangla. Translate '
    'MEANING, never word-by-word: rewrite each sentence the way '
    'a good Bangla textbook would say it, keeping the same '
    'information and tone. Use simple, easy Bangla a class 9 '
    'student understands: short sentences, common everyday '
    'words, no difficult literary words. Write ONLY in Bangla '
    'script: never use Chinese, Korean, Japanese, Arabic, Hindi, '
    'or any other script, and never mix a Latin word into a '
    'Bangla sentence. Keep the exact structure: keep every '
    'line break, keep letter and dialogue formatting, and do not '
    'merge or split sentences. Transliterate personal and place '
    'names into Bangla script instead of translating their '
    'meaning. Output ONLY the Bangla translation, nothing else: '
    'no explanations, no notes, no extra sentences.';

String translationUserPrompt(String text) =>
    'Translate this English text into Bangla:\n\n$text';

/// Stable 64-bit FNV-1a hash, hex-encoded. Stable across runs,
/// unlike Object.hashCode, so persisted cache keys survive a
/// restart.
String translationCacheKey(String text) {
  var hash = 0xcbf29ce484222325;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

class EnglishTranslationService {
  EnglishTranslationService({TranslationAiCall? aiCall})
      : _aiCall = aiCall ?? openRouterClient.chatRaw;

  final TranslationAiCall _aiCall;
  final Map<String, String> _memory = {};

  static const String enabledKey = 'english_reader_translate_bangla';
  static const String _cachePrefix = 'english_translation_v2_';

  /// Live switch state for surfaces that render translated
  /// fields without owning switch state (the shared guide
  /// answer screen): loadEnabled/setEnabled keep it in sync
  /// with the persisted preference, so translated fields
  /// rebuild the moment the switch flips, with no screen
  /// state threaded through the shared answer body.
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);

  Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(enabledKey) ?? false;
    enabledNotifier.value = value;
    return value;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, value);
    enabledNotifier.value = value;
  }

  /// Translates [text] to Bangla, or returns [text] unchanged
  /// when there is nothing to translate (empty, or no Latin
  /// letters — already Bangla, digits, or punctuation). Returns
  /// null ONLY when the model call fails or answers empty: the
  /// caller then shows the original plus a failure note.
  Future<String?> translate(String text) async {
    if (text.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(text)) {
      return text;
    }
    final key = translationCacheKey(text);
    final cached = _memory[key];
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_cachePrefix$key');
    if (stored != null && stored.isNotEmpty) {
      _memory[key] = stored;
      return stored;
    }
    final res = await _aiCall(
      systemPrompt: translationSystemPrompt,
      userPrompt: translationUserPrompt(text),
    );
    final out = res.text?.trim();
    if (out == null || out.isEmpty) return null;
    // Script-garbage output is a failure, never a cached row:
    // a leaked foreign-script token must not reach the student
    // or sit in the phone cache for every later view.
    if (translationHasScriptGarbage(out)) return null;
    _memory[key] = out;
    await prefs.setString('$_cachePrefix$key', out);
    return out;
  }
}

final englishTranslationService = EnglishTranslationService();
