// Q9 punctuation partial credit (English Paper-II, honest version).
// Q9 rows carry ONE whole-passage key: no item split exists in
// the book, so no item boundaries are invented here. The score
// is a diff of punctuation-mark sequences: the key's marks in
// order vs the student's marks in order, aligned by LCS. A mark
// counts only when the same mark appears at the same aligned
// position; wrong-order marks and extra marks earn nothing.
// Pure Dart (no Flutter import) so it is unit-testable.

/// Punctuation marks counted for Q9 scoring: standard English
/// marks plus curly quotes, dash variants, and the ellipsis
/// character. Letters, digits, and spaces are never marks.
const Set<String> punctuationMarks = {
  '.',
  ',',
  ';',
  ':',
  '?',
  '!',
  "'",
  '’',
  '‘',
  '"',
  '“',
  '”',
  '(',
  ')',
  '[',
  ']',
  '{',
  '}',
  '-',
  '–',
  '—',
  '…',
};

/// The punctuation-mark sequence of [text], in order.
List<String> extractPunctuationMarks(String text) {
  final marks = <String>[];
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (punctuationMarks.contains(ch)) marks.add(ch);
  }
  return marks;
}

/// Result of scoring one written punctuation answer against the
/// printed key passage. [marks] is out of [maxMarks].
class PunctuationScore {
  const PunctuationScore({
    required this.correct,
    required this.total,
    required this.maxMarks,
    required this.marks,
    required this.matched,
    required this.missed,
    required this.extra,
  });

  /// Marks the student placed correctly, in aligned order.
  final int correct;

  /// Marks in the key passage (0 = key has no marks to score).
  final int total;
  final int maxMarks;

  /// Score out of [maxMarks], rounded to the nearest 0.5.
  final double marks;

  /// The LCS sequence itself (the credited marks, in order).
  final List<String> matched;

  /// Key marks with no aligned student mark, in key order.
  final List<String> missed;

  /// Student marks with no aligned key mark, in student order.
  final List<String> extra;
}

/// Scores [userText] against [keyText] (both whole passages).
/// [maxMarks] is the row's printed marks (Q9 rows print 5).
/// A key with no marks cannot be scored: total 0, marks 0.0.
PunctuationScore scorePunctuation(
  String userText,
  String keyText, {
  int maxMarks = 5,
}) {
  final keyMarks = extractPunctuationMarks(keyText);
  final userMarks = extractPunctuationMarks(userText);
  if (keyMarks.isEmpty) {
    return PunctuationScore(
      correct: 0,
      total: 0,
      maxMarks: maxMarks,
      marks: 0,
      matched: const [],
      missed: const [],
      extra: userMarks,
    );
  }
  // LCS of key vs user marks (aligned positions only).
  final table = List.generate(
    keyMarks.length + 1,
    (_) => List<int>.filled(userMarks.length + 1, 0),
  );
  for (var i = 1; i <= keyMarks.length; i++) {
    for (var j = 1; j <= userMarks.length; j++) {
      table[i][j] = keyMarks[i - 1] == userMarks[j - 1]
          ? table[i - 1][j - 1] + 1
          : (table[i - 1][j] > table[i][j - 1]
              ? table[i - 1][j]
              : table[i][j - 1]);
    }
  }
  final matched = <String>[];
  var i = keyMarks.length;
  var j = userMarks.length;
  while (i > 0 && j > 0) {
    if (keyMarks[i - 1] == userMarks[j - 1]) {
      matched.add(keyMarks[i - 1]);
      i--;
      j--;
    } else if (table[i - 1][j] >= table[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }
  final matchedInOrder = matched.reversed.toList();
  // Missed = key marks minus the LCS (multiset walk, key order).
  final missed = <String>[];
  var m = 0;
  for (final mark in keyMarks) {
    if (m < matchedInOrder.length && matchedInOrder[m] == mark) {
      m++;
    } else {
      missed.add(mark);
    }
  }
  // Extra = user marks minus the LCS (multiset walk, user order).
  final extra = <String>[];
  m = 0;
  for (final mark in userMarks) {
    if (m < matchedInOrder.length && matchedInOrder[m] == mark) {
      m++;
    } else {
      extra.add(mark);
    }
  }
  final correct = matchedInOrder.length;
  final raw = maxMarks * correct / keyMarks.length;
  final rounded = (raw * 2).round() / 2;
  return PunctuationScore(
    correct: correct,
    total: keyMarks.length,
    maxMarks: maxMarks,
    marks: rounded.clamp(0, maxMarks).toDouble(),
    matched: matchedInOrder,
    missed: missed,
    extra: extra,
  );
}
