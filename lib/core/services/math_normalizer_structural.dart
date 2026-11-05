part of 'math_normalizer.dart';

/// Structural pass: absolute-value bars, brace groups and √ radicands.
/// Inner content is converted recursively, so nested constructs work.
String _structural(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '|') {
      // Absolute value ONLY with no spaces hugging the bars.
      final close = s.indexOf('|', i + 1);
      if (close != -1 &&
          close > i + 1 &&
          s[i + 1] != ' ' &&
          s[close - 1] != ' ') {
        out.write(r'\left|');
        out.write(_convertMath(s.substring(i + 1, close)));
        out.write(r'\right|');
        i = close + 1;
      } else {
        // Lone / spaced bar = separator, never a bare '|' in $...$.
        out.write(r'\mid');
        i++;
      }
    } else if (c == '{') {
      final close = _matching(s, i, '{', '}');
      if (close == -1) {
        out.write(r'\{');
        i++;
      } else {
        out.write(r'\left\{');
        out.write(_convertMath(s.substring(i + 1, close)));
        out.write(r'\right\}');
        i = close + 1;
      }
    } else if (c == '}') {
      out.write(r'\}'); // Unmatched: escaped, never dropped.
      i++;
    } else if (c == '√') {
      final j = i + 1;
      if (j < s.length && s[j] == '(') {
        final close = _matching(s, j, '(', ')');
        if (close == -1) {
          out.write(c);
          i++;
        } else {
          out.write(r'\sqrt{');
          out.write(_convertMath(s.substring(j + 1, close)));
          out.write('}');
          i = close + 1;
        }
      } else if (j < s.length && _isDigitOrMathLetter(s[j])) {
        var k = j;
        if (_isDigit(s[j])) {
          while (k < s.length && _isDigit(s[k])) {
            k++;
          }
        } else {
          while (k < s.length && _isMathLetter(s[k])) {
            k++;
          }
        }
        out.write(r'\sqrt{');
        out.write(s.substring(j, k));
        out.write('}');
        i = k;
      } else {
        out.write(c); // No radicand: leave, never crash.
        i++;
      }
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

const _supMap = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
};

const _subMap = {
  '₀': '0',
  '₁': '1',
  '₂': '2',
  '₃': '3',
  '₄': '4',
  '₅': '5',
  '₆': '6',
  '₇': '7',
  '₈': '8',
  '₉': '9',
};

bool _isSuperOrSub(String c) =>
    _supMap.containsKey(c) || _subMap.containsKey(c);

/// Unicode superscripts/subscripts -> ^{n} / _{n}; multi-digit runs
/// group into one brace pair (x¹² -> x^{12}).
String _superSub(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (_supMap.containsKey(c)) {
      final digits = StringBuffer();
      while (i < s.length && _supMap.containsKey(s[i])) {
        digits.write(_supMap[s[i]]);
        i++;
      }
      out.write('^{${digits.toString()}}');
    } else if (_subMap.containsKey(c)) {
      final digits = StringBuffer();
      while (i < s.length && _subMap.containsKey(s[i])) {
        digits.write(_subMap[s[i]]);
        i++;
      }
      out.write('_{${digits.toString()}}');
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

const _symbolMap = {
  '∈': r'\in',
  '∪': r'\cup',
  '∩': r'\cap',
  '∖': r'\setminus',
  'π': r'\pi',
  '∞': r'\infty',
  '≤': r'\leq',
  '≥': r'\geq',
  '≠': r'\neq',
  '±': r'\pm',
  '∅': r'\emptyset',
  '×': r'\times',
  '÷': r'\div',
  'θ': r'\theta',
  'α': r'\alpha',
  'β': r'\beta',
  'Δ': r'\Delta',
};

String _symbols(String s) {
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final cmd = _symbolMap[c];
    if (cmd == null) {
      out.write(c);
    } else {
      out.write(cmd);
      // A LaTeX command name gobbles a following letter ("\pi" + "x"
      // would parse as "\pix"), so separate it with a space, which
      // LaTeX consumes as the command terminator.
      if (i + 1 < s.length && _isAsciiLetter(s[i + 1])) {
        out.write(' ');
      }
    }
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Fractions: a/b -> \frac{a}{b} only in clear math context.
// ---------------------------------------------------------------------------

