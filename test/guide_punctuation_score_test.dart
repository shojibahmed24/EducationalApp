// Q9 punctuation diff-score tests. All passages below are
// invented test sentences, never guide text. The scoring rule:
// key marks vs student marks in order, aligned by LCS; a mark
// counts only at the same aligned position; wrong-order and
// extra marks earn nothing; score rounds to the nearest 0.5.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/punctuation_score.dart';

void main() {
  test('exact match scores full marks', () {
    const key = 'Rahim said, I will go home. Then he left!';
    final score = scorePunctuation(key, key);
    expect(score.total, 3);
    expect(score.correct, 3);
    expect(score.marks, 5);
    expect(score.missed, isEmpty);
    expect(score.extra, isEmpty);
  });

  test('empty answer scores zero', () {
    final score = scorePunctuation('', 'Rahim said, I will go home.');
    expect(score.correct, 0);
    expect(score.marks, 0);
  });

  test('partial credit is proportional', () {
    // Key marks: , ; : . (4). Student keeps , ; only.
    final score = scorePunctuation('A, B; C D', 'A, B; C: D.');
    expect(score.total, 4);
    expect(score.correct, 2);
    expect(score.marks, 2.5);
  });

  test('wrong-order marks are not credited', () {
    // Key marks: , . — student swaps them: . ,
    final score = scorePunctuation('A. B,', 'A, B.');
    expect(score.total, 2);
    expect(score.correct, 1);
    expect(score.marks, 2.5);
  });

  test('extra marks are not credited but are reported', () {
    final score = scorePunctuation('A, B.!', 'A, B.');
    expect(score.correct, 2);
    expect(score.marks, 5);
    expect(score.extra, ['!']);
    expect(score.missed, isEmpty);
  });

  test('missing marks reduce the score', () {
    // Key marks: , ; : ? . (5). Student drops the final full stop.
    final score = scorePunctuation('A, B; C: D? E', 'A, B; C: D? E.');
    expect(score.total, 5);
    expect(score.correct, 4);
    expect(score.marks, 4);
  });

  test('score rounds to the nearest 0.5', () {
    // 1 of 3 -> 5/3 = 1.666 -> 1.5; 2 of 3 -> 3.333 -> 3.5.
    expect(scorePunctuation('A, B C', 'A, B; C.').marks, 1.5);
    expect(scorePunctuation('A, B; C', 'A, B; C.').marks, 3.5);
  });

  test('key with no marks cannot be scored', () {
    final score = scorePunctuation('hello world', 'hello world');
    expect(score.total, 0);
    expect(score.marks, 0);
  });

  test('matched and missed breakdown follows the alignment', () {
    // Key: , . — student: . ! — LCS keeps only the full stop.
    final score = scorePunctuation('A. B!', 'A, B.');
    expect(score.matched, ['.']);
    expect(score.missed, [',']);
    expect(score.extra, ['!']);
  });

  test('extraction keeps order and curly marks', () {
    expect(
      extractPunctuationMarks('He said, “Hi!” — and left.'),
      [',', '“', '!', '”', '—', '.'],
    );
  });

  test('maxMarks parameter scales the score', () {
    // 1 of 2 marks: half of 5 = 2.5; half of 10 = 5.
    expect(scorePunctuation('A, B', 'A, B.').marks, 2.5);
    expect(
      scorePunctuation('A, B', 'A, B.', maxMarks: 10).marks,
      5,
    );
  });
}
