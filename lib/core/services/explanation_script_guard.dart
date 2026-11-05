// Script-garbage guard for AI explanations (2026-11-03): the
// model sometimes emits Bengali words as Latin gibberish
// (transliterated fragments), Arabic script, or accented Latin
// letters. Those outputs must never reach the student: the
// service treats a garbled solution as failed (retry, then the
// honest note). Legitimate English words from the guide
// ('celebrate') are plain ASCII and pass. Pure-ASCII
// transliterations cannot be told apart from English words by
// code, so the prompt's script rule is the guard there.
// 2026-11-03 extension: East Asian scripts (Chinese, Korean
// Hangul, Japanese kana) are garbage too — a free model leaked
// a Korean word into a Bangla passage translation on the
// user's phone, and translations had no guard at all.
import '../models/solution_model.dart';

bool _isArabic(int c) =>
    (c >= 0x0600 && c <= 0x06FF) ||
    (c >= 0x0750 && c <= 0x077F) ||
    (c >= 0x08A0 && c <= 0x08FF) ||
    (c >= 0xFB50 && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);

bool _isBengali(int c) => c >= 0x0980 && c <= 0x09FF;

bool _isLatin(int c) =>
    (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

bool _isExtendedLatin(int c) =>
    (c >= 0x00C0 && c <= 0x024F) || (c >= 0x1E00 && c <= 0x1EFF);

bool _isEastAsian(int c) =>
    (c >= 0x3400 && c <= 0x4DBF) || // CJK extension A
    (c >= 0x4E00 && c <= 0x9FFF) || // CJK unified
    (c >= 0xAC00 && c <= 0xD7AF) || // Hangul syllables
    (c >= 0x1100 && c <= 0x11FF) || // Hangul jamo
    (c >= 0x3040 && c <= 0x309F) || // Hiragana
    (c >= 0x30A0 && c <= 0x30FF); // Katakana

/// One whitespace-delimited token is garbage when it holds a
/// foreign-script character, an accented Latin letter, a bullet
/// inside a word, or Latin and Bengali letters mixed in one word.
bool _tokenIsGarbage(String token) {
  var hasLatin = false;
  var hasBengali = false;
  for (final c in token.runes) {
    if (_isArabic(c) || _isExtendedLatin(c) || _isEastAsian(c)) {
      return true;
    }
    if (c == 0x2022 && token.length > 1) return true;
    if (_isLatin(c)) hasLatin = true;
    if (_isBengali(c)) hasBengali = true;
  }
  return hasLatin && hasBengali;
}

/// True when any token in [text] is script garbage.
bool explanationHasScriptGarbage(String text) {
  for (final token in text.split(RegExp(r'\s+'))) {
    if (token.isNotEmpty && _tokenIsGarbage(token)) return true;
  }
  return false;
}

/// Translation outputs use the same token rule: a Bangla
/// translation must never carry a foreign-script token. The
/// translation service rejects such output (null, uncached)
/// instead of showing it and caching it on the phone.
bool translationHasScriptGarbage(String text) =>
    explanationHasScriptGarbage(text);

/// True when any field of a structured solution is garbage.
bool solutionHasScriptGarbage(StructuredSolution solution) {
  if (explanationHasScriptGarbage(solution.summary)) return true;
  if (explanationHasScriptGarbage(solution.finalAnswer)) return true;
  for (final step in solution.steps) {
    if (explanationHasScriptGarbage(step.title)) return true;
    if (explanationHasScriptGarbage(step.text)) return true;
  }
  final why = solution.whyCorrect;
  if (why != null && explanationHasScriptGarbage(why)) return true;
  final whyNot = solution.whyOthersWrong;
  if (whyNot != null && explanationHasScriptGarbage(whyNot)) return true;
  return false;
}
