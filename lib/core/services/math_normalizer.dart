// Converts plain-text / Unicode math into LaTeX segments wrapped in
// $...$ so SolutionRichText (flutter_math_fork Math.tex) typesets it.
//
// Pure Dart: no Flutter import, so it is unit-testable without a
// widget binding and reusable anywhere plain text becomes math.
//
// Conservative by design, per the approved plan:
//  * Bangla script, Bangla digits, dates and prose are never altered.
//  * Existing $...$ segments pass through untouched.
//  * A fraction a/b becomes \frac{a}{b} only in clear math context;
//    date-like chains (10/02/2024), Bangla-digit fractions and slashes
//    between prose words stay inline.
//  * Set-builder braces become \left\{...\right\} only when the brace
//    group contains no Bangla script; otherwise the braces stay literal
//    and only the pure-symbol runs inside are converted.
//  * No bare '|' is ever emitted inside $...$: absolute value uses
//    \left|...\right|, a separator bar uses \mid.
//  * Unparseable input is returned unwrapped, never crashed on and
//    never dropped. Empty input returns empty output.

/// Converts plain text [input] into the same text with converted math
/// runs wrapped in `$...$` segments. Existing `$...$` segments are

part 'math_normalizer_structural.dart';
part 'math_normalizer_fractions.dart';
part 'math_normalizer_chars.dart';

String normalizeMathText(String input) {
  if (input.isEmpty) return '';
  final out = StringBuffer();
  // Split on existing $...$ segments first; never re-process inside.
  final dollar = RegExp(r'\$[^$]*\$');
  var cursor = 0;
  for (final m in dollar.allMatches(input)) {
    if (m.start > cursor) {
      out.write(_processPlain(input.substring(cursor, m.start)));
    }
    out.write(m.group(0)); // Existing segment, verbatim.
    cursor = m.end;
  }
  if (cursor < input.length) {
    out.write(_processPlain(input.substring(cursor)));
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Plain-chunk processing: split into math runs vs prose.
// ---------------------------------------------------------------------------

String _processPlain(String s) {
  final out = StringBuffer();
  final run = StringBuffer();

  void flushRun() {
    if (run.isEmpty) return;
    final raw = run.toString();
    run.clear();
    var start = 0;
    while (start < raw.length && raw[start] == ' ') {
      start++;
    }
    var end = raw.length;
    while (end > start && raw[end - 1] == ' ') {
      end--;
    }
    final core = raw.substring(start, end);
    if (core.isEmpty) {
      out.write(raw); // Whitespace only: keep it as-is.
      return;
    }
    if (_looksLikeMath(core)) {
      out.write(raw.substring(0, start));
      out.write('\$');
      out.write(_convertMath(core));
      out.write('\$');
      out.write(raw.substring(end));
    } else {
      out.write(raw); // Lone number / word / date: never wrapped.
    }
  }

  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '{') {
      final close = _matching(s, i, '{', '}');
      if (close == -1) {
        flushRun();
        out.write('{'); // Unmatched brace: literal prose.
        i++;
      } else {
        final inner = s.substring(i + 1, close);
        if (_containsBangla(inner)) {
          // Braces stay literal; only pure-symbol runs inside convert.
          flushRun();
          out.write('{');
          out.write(_processPlain(inner));
          out.write('}');
        } else {
          run.write(s.substring(i, close + 1));
        }
        i = close + 1;
      }
    } else if (_isMathChar(c)) {
      run.write(c);
      i++;
    } else {
      // Bangla script, newlines, quotes, '?' and everything else:
      // terminates a math run and is never altered.
      flushRun();
      out.write(c);
      i++;
    }
  }
  flushRun();
  return out.toString();
}

/// A math run is a maximal span of math characters that contains at least
/// one math operator/symbol. A lone plain number or word is NOT math.
/// A run of pure operator punctuation is NOT math either: the '-'
/// in Bangla prose ('ক-এর') and similar punctuation runs have no
/// operand, so they stay inline instead of wrapping as $-$.
bool _looksLikeMath(String core) {
  var hasOperand = false;
  for (var i = 0; i < core.length; i++) {
    final c = core[i];
    if (_isDigitOrMathLetter(c) ||
        _isSuperOrSub(c) ||
        '∈∪∩∖∞≤≥≠±∅×÷√'.contains(c)) {
      hasOperand = true;
      break;
    }
  }
  if (!hasOperand) return false;
  const ops = '=<>+-×÷√∈∪∩∖^|π∞≤≥≠±∅θαβΔ';
  for (var i = 0; i < core.length; i++) {
    final c = core[i];
    if (ops.contains(c) || _isSuperOrSub(c)) return true;
  }
  if (core.contains('://') || core.startsWith('www.')) {
    return false; // URL / path: never math.
  }
  // A convertible fraction also qualifies. The fraction matcher itself
  // rejects date chains, so "10/02/2024" stays inline here too.
  return _convertFractions(core) != core;
}

// ---------------------------------------------------------------------------
// Math-run conversion.
// ---------------------------------------------------------------------------

String _convertMath(String core) {
  // Standalone N/Z/Q/R map to \mathbb ONLY in a run containing ∈.
  final setBuilder = core.contains('∈');
  var out = _structural(core);
  out = _superSub(out);
  out = _symbols(out);
  out = _fractions(out);
  if (setBuilder) out = _mathbb(out);
  return out;
}

