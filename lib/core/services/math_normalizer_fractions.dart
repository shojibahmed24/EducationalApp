part of 'math_normalizer.dart';

String _fractions(String s) => _convertFractions(s);

String _convertFractions(String s) {
  final out = StringBuffer();
  var copied = 0; // s[0..copied) already written.
  var i = 0;
  while (i < s.length) {
    if (s[i] == '/') {
      final ls = _leftOperandStart(s, i);
      if (ls != -1) {
        final re = _rightOperandEnd(s, i);
        if (re != -1) {
          out.write(s.substring(copied, ls));
          out.write(
            '\\frac{${s.substring(ls, i)}}{${s.substring(i + 1, re)}}',
          );
          i = re;
          copied = re;
          continue;
        }
      }
    }
    i++;
  }
  out.write(s.substring(copied));
  return out.toString();
}

/// Start index of the left operand ending just before [slash], or -1.
/// Operands are Latin letters/digits or parenthesized/brace groups.
/// Rejects date chains (digit or '/' before) and decimals ('.' before).
int _leftOperandStart(String s, int slash) {
  final j = slash - 1;
  if (j < 0) return -1;
  final c = s[j];
  int start;
  if (_isDigit(c) || _isAsciiLetter(c)) {
    var k = j;
    while (k >= 0 && (_isDigit(s[k]) || _isAsciiLetter(s[k]))) {
      k--;
    }
    start = k + 1;
    // A letter run preceded by '\' is a LaTeX command: include it.
    if (start - 1 >= 0 && s[start - 1] == '\\') {
      start = start - 1;
    }
  } else if (c == ')') {
    final open = _matchingBack(s, j, ')', '(');
    if (open == -1) return -1;
    start = open;
    // Function name before the parens, e.g. f(x).
    var k = open - 1;
    while (k >= 0 && _isAsciiLetter(s[k])) {
      k--;
    }
    start = k + 1;
  } else if (c == '}') {
    final open = _matchingBack(s, j, '}', '{');
    if (open == -1) return -1;
    if (open - 1 >= 0 && (s[open - 1] == '^' || s[open - 1] == '_')) {
      // Base^{...} / base_{...}: include the base too.
      final b = open - 2;
      if (b >= 0 && (_isDigit(s[b]) || _isAsciiLetter(s[b]))) {
        var k = b;
        while (k >= 0 && (_isDigit(s[k]) || _isAsciiLetter(s[k]))) {
          k--;
        }
        start = k + 1;
      } else if (b >= 0 && s[b] == ')') {
        final open2 = _matchingBack(s, b, ')', '(');
        if (open2 == -1) return -1;
        start = open2;
        var k = open2 - 1;
        while (k >= 0 && _isAsciiLetter(s[k])) {
          k--;
        }
        start = k + 1;
      } else {
        start = open;
      }
    } else if (open - 1 >= 0 && _isAsciiLetter(s[open - 1])) {
      // Command with braces, e.g. \sqrt{17}.
      var k = open - 1;
      while (k >= 0 && _isAsciiLetter(s[k])) {
        k--;
      }
      start = (k >= 0 && s[k] == '\\') ? k : open;
    } else {
      start = open;
    }
  } else {
    return -1;
  }
  if (start - 1 >= 0) {
    final p = s[start - 1];
    if (_isDigit(p) || p == '/' || p == '.') return -1;
  }
  return start;
}

/// End-exclusive index of the right operand starting just after [slash],
/// or -1. Rejects date chains (digit or '/' after) and decimals.
int _rightOperandEnd(String s, int slash) {
  final k = slash + 1;
  if (k >= s.length) return -1;
  final c = s[k];
  int end;
  if (c == '\\') {
    var e = k + 1;
    while (e < s.length && _isAsciiLetter(s[e])) {
      e++;
    }
    if (e == k + 1) return -1; // Lone backslash.
    if (e < s.length && s[e] == '{') {
      final close = _matching(s, e, '{', '}');
      if (close == -1) return -1;
      end = close + 1;
    } else {
      end = e;
    }
  } else if (_isDigit(c) || _isAsciiLetter(c)) {
    var e = k;
    while (e < s.length && (_isDigit(s[e]) || _isAsciiLetter(s[e]))) {
      e++;
    }
    end = e;
  } else if (c == '(') {
    final close = _matching(s, k, '(', ')');
    if (close == -1) return -1;
    end = close + 1;
  } else if (c == '{') {
    final close = _matching(s, k, '{', '}');
    if (close == -1) return -1;
    end = close + 1;
  } else {
    return -1;
  }
  if (end < s.length) {
    final n = s[end];
    if (_isDigit(n) || n == '/' || n == '.') return -1;
  }
  // Prose-word guard: "and/or", "for/example" must not become a
  // fraction. Both sides pure letters, left word-length >= 3, means
  // prose, not math (school math uses 1-2 letter variables here).
  final left = s.substring(_leftOperandStart(s, slash), slash);
  final right = s.substring(k, end);
  if (_isPureLetters(left) &&
      _isPureLetters(right) &&
      left.length >= 3 &&
      right.length >= 2) {
    return -1;
  }
  return end;
}

bool _isPureLetters(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    if (!_isAsciiLetter(s[i])) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// \mathbb mapping (set-builder runs only; caller checks for ∈).
// ---------------------------------------------------------------------------

String _mathbb(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (s.startsWith(r'\mathbb{', i)) {
      // Already converted: skip the whole span, never double-wrap.
      final close = _matching(s, i + 7, '{', '}');
      if (close == -1) {
        out.write(s[i]);
        i++;
      } else {
        out.write(s.substring(i, close + 1));
        i = close + 1;
      }
      continue;
    }
    final c = s[i];
    if ((c == 'N' || c == 'Z' || c == 'Q' || c == 'R') &&
        (i == 0 || !_isAlnum(s[i - 1])) &&
        (i + 1 >= s.length || !_isAlnum(s[i + 1]))) {
      out.write('\\mathbb{$c}');
    } else {
      out.write(c);
    }
    i++;
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Character classes and matching helpers.
// ---------------------------------------------------------------------------

