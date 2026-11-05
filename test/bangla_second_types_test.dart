// Tests for the Bangla 2nd Paper picker split logic (three
// levels, 2026-11-04 refinement). Fixtures mirror the verified
// live id shapes only; no guide text is used.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_potro.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_types.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_second_strings.dart';

void main() {
  test('picker order is exactly the eleven অধ্যায় items in order', () {
    expect(banglaSecondTypesInOrder, [
      BanglaSecondType.mcq,
      BanglaSecondType.onucched,
      BanglaSecondType.chithipotro,
      BanglaSecondType.sarangsho,
      BanglaSecondType.sarmormo,
      BanglaSecondType.bhab,
      BanglaSecondType.songbad,
      BanglaSecondType.rochona,
      BanglaSecondType.onubad,
      BanglaSecondType.suggestion,
      BanglaSecondType.modelTest,
    ]);
  });

  test('routes map every type to its screen', () {
    expect(banglaSecondRoute(BanglaSecondType.mcq), '/bangla-second-mcq');
    expect(banglaSecondRoute(BanglaSecondType.onucched),
        '/bangla-second-nirmiti?kind=onucched');
    expect(banglaSecondRoute(BanglaSecondType.chithipotro),
        '/bangla-second-nirmiti?kind=potro');
    expect(banglaSecondRoute(BanglaSecondType.sarangsho),
        '/bangla-second-nirmiti?kind=sarangsho');
    expect(banglaSecondRoute(BanglaSecondType.sarmormo),
        '/bangla-second-nirmiti?kind=sarmormo');
    expect(banglaSecondRoute(BanglaSecondType.bhab),
        '/bangla-second-nirmiti?kind=bhab');
    expect(banglaSecondRoute(BanglaSecondType.songbad),
        '/bangla-second-nirmiti?kind=songbad');
    expect(banglaSecondRoute(BanglaSecondType.rochona),
        '/bangla-second-nirmiti?kind=probondho');
    expect(banglaSecondRoute(BanglaSecondType.onubad),
        '/bangla-second-nirmiti?kind=onubad');
    expect(banglaSecondRoute(BanglaSecondType.suggestion),
        '/bangla-second-suggestion');
    expect(banglaSecondRoute(BanglaSecondType.modelTest),
        '/bangla-second-model-tests');
  });

  test('every type has a non-empty label in both languages', () {
    for (final type in banglaSecondTypesInOrder) {
      expect(banglaSecondTypeLabel(type, banglaSecondStringsBn).isNotEmpty,
          isTrue);
      expect(banglaSecondTypeLabel(type, banglaSecondStringsEn).isNotEmpty,
          isTrue);
    }
    expect(banglaSecondStringsBn['typeChithipotro'], 'চিঠিপত্র');
    expect(banglaSecondStringsEn['typeChithipotro'], 'Letters');
    expect(banglaSecondStringsBn['typeRochona'], 'রচনা');
  });

  test('nirmiti kind prefixes parse from ids', () {
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-onucched-001'),
        'onucched');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-potro-047'), 'potro');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-sarangsho-012'),
        'sarangsho');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-sarmormo-003'),
        'sarmormo');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-bhab-020'), 'bhab');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-songbad-007'),
        'songbad');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-probondho-038'),
        'probondho');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-onubad-005'), 'onubad');
    expect(parseBanglaSecondNirmitiKind('ban2-ch19-mcq-bank-003'), isNull);
  });

  test('nirmiti kind matching: potro kind matches every potro row', () {
    expect(nirmitiRowMatchesKind('ban2-nirmiti-potro-001', 'potro'), isTrue);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-potro-048', 'potro'), isTrue);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-onucched-001', 'potro'),
        isFalse);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-probondho-001', 'probondho'),
        isTrue);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-bhab-001', 'probondho'),
        isFalse);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-sarangsho-001', 'sarangsho'),
        isTrue);
  });

  test('potro divisions cover 001-048 with no gaps or overlaps', () {
    expect(potroDivisionForNumber(1), 'personal');
    expect(potroDivisionForNumber(19), 'personal');
    expect(potroDivisionForNumber(20), 'invitation');
    expect(potroDivisionForNumber(23), 'invitation');
    expect(potroDivisionForNumber(24), 'newspaper');
    expect(potroDivisionForNumber(28), 'newspaper');
    expect(potroDivisionForNumber(29), 'manpotro');
    expect(potroDivisionForNumber(32), 'manpotro');
    expect(potroDivisionForNumber(33), 'application');
    expect(potroDivisionForNumber(46), 'application');
    expect(potroDivisionForNumber(47), 'business');
    expect(potroDivisionForNumber(48), 'business');
    expect(potroDivisionForNumber(0), isNull);
    expect(potroDivisionForNumber(49), isNull);
    var covered = 0;
    for (final d in banglaSecondPotroDivisions) {
      covered += d.$3 - d.$2 + 1;
    }
    expect(covered, 48);
    for (var n = 1; n <= 48; n++) {
      expect(potroDivisionForNumber(n), isNotNull);
    }
  });

  test('potro number parsing', () {
    expect(parseBanglaSecondPotroNumber('ban2-nirmiti-potro-001'), 1);
    expect(parseBanglaSecondPotroNumber('ban2-nirmiti-potro-048'), 48);
    expect(parseBanglaSecondPotroNumber('ban2-nirmiti-onucched-001'),
        isNull);
    expect(parseBanglaSecondPotroNumber('ban2-ch19-mcq-bank-003'), isNull);
  });

  test('bank পরিচ্ছেদ parsing and extra bucket', () {
    expect(parseBanglaSecondChapter('ban2-ch19-mcq-bank-003'), 19);
    expect(parseBanglaSecondChapter('ban2-ch5-mcq-bank-001'), 5);
    expect(parseBanglaSecondChapter('ban2-ch43-mcq-bank-026'), 43);
    expect(parseBanglaSecondChapter('ban2-extra-mcq-bank-001'), isNull);
    expect(isBanglaSecondExtraBankId('ban2-extra-mcq-bank-041'), isTrue);
    expect(isBanglaSecondExtraBankId('ban2-ch19-mcq-bank-003'), isFalse);
  });

  test('grouping preserves first-appearance order', () {
    final grouped = groupBanglaSecondRows<String, String>(
        ['b', 'a', 'b', 'c'], (s) => s);
    expect(grouped.keys.toList(), ['b', 'a', 'c']);
    expect(grouped['b'], ['b', 'b']);
  });

  test('model set number parsing', () {
    expect(parseBanglaSecondModelSetNumber('model-1'), 1);
    expect(parseBanglaSecondModelSetNumber('model-12'), 12);
    expect(parseBanglaSecondModelSetNumber('model-40'), 40);
    expect(parseBanglaSecondModelSetNumber('model-x'), isNull);
    expect(parseBanglaSecondModelSetNumber('board-2024'), isNull);
  });

  test('board year parsing from Bangla-digit set ids', () {
    expect(parseBanglaSecondBoardYear('ঢাকা বোর্ড ২০২৪'), 2024);
    expect(parseBanglaSecondBoardYear('রাজশাহী বোর্ড ২০২৩'), 2023);
    expect(parseBanglaSecondBoardYear('model-1'), isNull);
    expect(parseBanglaSecondBoardYear('ঢাকা বোর্ড 2024'), isNull);
  });
}
