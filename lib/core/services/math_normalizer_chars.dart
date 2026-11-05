part of 'math_normalizer.dart';

bool _isDigit(String c) {
  final code = c.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

bool _isAsciiLetter(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A);
}

bool _isAlnum(String c) => _isDigit(c) || _isAsciiLetter(c);

bool _isMathLetter(String c) {
  final code = c.codeUnitAt(0);
  return _isAsciiLetter(c) ||
      (code >= 0x0370 && code <= 0x03FF) || // Greek
      (code >= 0x1F00 && code <= 0x1FFF); // Greek extended
}

bool _isDigitOrMathLetter(String c) => _isDigit(c) || _isMathLetter(c);

/// Latin/Greek letters, digits, operators, set symbols, superscripts,
/// parens/brackets/braces and the punctuation that joins math tokens.
/// Bangla script (U+0980–U+09FF, danda U+0964–U+0965) is NOT in this set,
/// so it always terminates a math run.
bool _isMathChar(String c) {
  if (_isDigitOrMathLetter(c)) return true;
  if (_isSuperOrSub(c)) return true;
  // Operator / set symbols (outside the Greek block).
  if ('∈∪∩∖∞≤≥≠±∅×÷√'.contains(c)) return true;
  return '()[]{}^_/.,:;|!%+<>=*-\''.contains(c) || c == ' ';
}

/// Index of the [closeCh] matching the opener at [open], or -1.
int _matching(String s, int open, String openCh, String closeCh) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == openCh) depth++;
    if (s[i] == closeCh) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// Index of the [openCh] matching the closer at [close], or -1.
int _matchingBack(String s, int close, String closeCh, String openCh) {
  var depth = 0;
  for (var i = close; i >= 0; i--) {
    if (s[i] == closeCh) depth++;
    if (s[i] == openCh) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

bool _containsBangla(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    if ((code >= 0x0980 && code <= 0x09FF) ||
        (code >= 0x0964 && code <= 0x0965)) {
      return true;
    }
  }
  return false;
}
