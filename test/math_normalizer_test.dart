import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/math_normalizer.dart';

void main() {
  test('f(a) polynomial with unicode superscripts converts', () {
    expect(
      normalizeMathText('f(a) = a³ - 4a² + 5a + 2b'),
      r'$f(a) = a^{3} - 4a^{2} + 5a + 2b$',
    );
  });

  test('b = 10/2 converts the fraction', () {
    expect(normalizeMathText('b = 10/2'), r'$b = \frac{10}{2}$');
  });

  test('set-builder maps standalone N to mathbb', () {
    expect(
      normalizeMathText('U = {x ∈ N : x < 15}'),
      r'$U = \left\{x \in \mathbb{N} : x < 15\right\}$',
    );
  });

  test('mixed Bangla+math keeps Bangla verbatim, braces literal', () {
    const input = 'U = {x ∈ N : x বিজোড় সংখ্যা এবং 3 < x < 15}';
    final out = normalizeMathText(input);
    expect(out, contains('বিজোড় সংখ্যা এবং'));
    expect(out, contains(r'$x \in \mathbb{N} : x$'));
    expect(out, contains(r'$3 < x < 15$'));
    expect(out, isNot(contains(r'\left\{')));
    // Bangla words must not sit inside a $...$ segment.
    for (final m in RegExp(r'\$[^$]*\$').allMatches(out)) {
      expect(m.group(0), isNot(contains('বিজোড়')));
    }
  });

  test('Bangla-digit fraction stays inline', () {
    expect(normalizeMathText('৩/৫ অংশ'), '৩/৫ অংশ');
  });

  test('Bangla date stays inline', () {
    expect(normalizeMathText('১০/০২/২০২৪'), '১০/০২/২০২৪');
  });

  test('Latin date stays inline', () {
    expect(normalizeMathText('10/02/2024'), '10/02/2024');
  });

  test('existing \$x^2\$ segment is preserved verbatim', () {
    const input = 'আমরা জানি \$x^2\$ হলো বর্গ';
    expect(normalizeMathText(input), input);
  });

  test('pure Bangla string is unchanged', () {
    const input = 'আমি ভাত খাই';
    expect(normalizeMathText(input), input);
  });

  test('empty string returns empty', () {
    expect(normalizeMathText(''), '');
  });

  test('2√17 converts to sqrt', () {
    expect(normalizeMathText('2√17'), r'$2\sqrt{17}$');
  });

  test('absolute value uses left/right bars, no bare pipe', () {
    expect(normalizeMathText('|x|'), r'$\left|x\right|$');
  });

  test('multi-digit superscript groups into one brace pair', () {
    expect(normalizeMathText('x¹² + y₀'), r'$x^{12} + y_{0}$');
  });

  test('N without set-builder membership is not mapped', () {
    expect(normalizeMathText('N = 5'), r'$N = 5$');
  });

  test('set union symbol converts', () {
    expect(normalizeMathText('A ∪ B = B ∪ A'), r'$A \cup B = B \cup A$');
  });

  test('Bangla prose slash stays inline', () {
    expect(normalizeMathText('এবং/অথবা'), 'এবং/অথবা');
  });

  test('Bangla genitive hyphen stays inline, never math minus', () {
    expect(
      normalizeMathText('ক-এর নকল গাইড উত্তর'),
      'ক-এর নকল গাইড উত্তর',
    );
    expect(normalizeMathText('খ-এর মান'), 'খ-এর মান');
  });

  test('bare operator between Bangla words stays inline', () {
    expect(normalizeMathText('ক+খ'), 'ক+খ');
  });

  test('real math minus still converts', () {
    expect(normalizeMathText('x-3'), r'$x-3$');
  });
}
