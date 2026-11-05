// Phase 2 gap plan — quiz scoring guards (pure, offline):
// bank-section + NULL-key pool exclusion, multi-key variant
// parsing/mapping, and the Q9 non-scorable guard. The Q9
// item-wise breakdown is deliberately NOT implemented here:
// Paper-II Q9 rows carry one whole-passage key, no options,
// and no per-item data (see report), so no test invents it.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_pool.dart';

GuideBankQuestion _row({
  required String id,
  String type = 'mcq',
  String? section,
  bool hasKey = true,
  List<String> options = const ['A', 'B', 'C', 'D'],
  String? setId,
  bool guideError = false,
}) =>
    GuideBankQuestion(
      id: id,
      questionText: 'q',
      questionType: type,
      options: options,
      serverHasKey: hasKey,
      setId: setId,
      guideError: guideError,
      section: section,
    );

void main() {
  group('Phase 2 pool exclusions', () {
    test('bank-section MCQ never enters the pool', () {
      expect(isScorableGuideMcq(_row(id: 'b-1', section: 'bank')),
          isFalse);
    });
    test('bank-section with a key is still excluded', () {
      // Bank rows carry no solution by owner decision; a
      // reported key must not smuggle one into scoring.
      expect(
          isScorableGuideMcq(
              _row(id: 'b-2', section: 'bank', hasKey: true)),
          isFalse);
    });
    test('NULL-key rows never enter the pool', () {
      expect(isScorableGuideMcq(_row(id: 'u-1', hasKey: false)),
          isFalse);
      expect(
          isScorableGuideMcq(
              _row(id: 'u-2', section: 'bank', hasKey: false)),
          isFalse);
    });
    test('Q9-style punctuation rows never enter the pool', () {
      // No options, not MCQ: a whole-passage punctuation item
      // cannot be answered single-select, so it is unscorable.
      expect(
          isScorableGuideMcq(_row(
              id: 'eng2-q9-1',
              type: 'punctuation',
              section: 'punctuation',
              options: [])),
          isFalse);
    });
    test('keyed non-bank MCQ still enters the pool', () {
      expect(isScorableGuideMcq(_row(id: 'ok-1')), isTrue);
      expect(isScorableGuideMcq(_row(id: 'ok-2', section: 'mcq')),
          isTrue);
    });
  });

  group('parseAcceptedAnswerKeys', () {
    test('JSON list decodes to its variants', () {
      expect(parseAcceptedAnswerKeys('["Even if", "Although"]'),
          ['Even if', 'Although']);
      expect(parseAcceptedAnswerKeys('["have", "enjoy"]'),
          ['have', 'enjoy']);
    });
    test('single letter and single word stay one variant', () {
      expect(parseAcceptedAnswerKeys('ক'), ['ক']);
      expect(parseAcceptedAnswerKeys('  Actually  '), ['Actually']);
    });
    test('JSON string decodes to one variant', () {
      expect(parseAcceptedAnswerKeys('"ক"'), ['ক']);
    });
    test('empty input yields no variants', () {
      expect(parseAcceptedAnswerKeys(''), isEmpty);
      expect(parseAcceptedAnswerKeys('   '), isEmpty);
    });
    test('empty list entries are filtered', () {
      expect(parseAcceptedAnswerKeys('["a", "", " b "]'), ['a', 'b']);
    });
    test('unparseable input degrades to one literal variant', () {
      expect(parseAcceptedAnswerKeys('["a"'), ['["a"']);
    });
  });

  group('acceptedOptionIndices', () {
    test('word-bank variants map to option indices', () {
      const options = [
        'overcome',
        'rise',
        'be',
        'enjoy',
        'come',
        'suffer',
        'walk',
        'pollute',
        'have',
      ];
      expect(acceptedOptionIndices(['have', 'enjoy'], options), [3, 8]);
    });
    test('letter variants map by Edge order', () {
      expect(acceptedOptionIndices(['খ', 'ঘ'], ['A', 'B', 'C', 'D']),
          [1, 3]);
    });
    test('mixed letter and word variants both map', () {
      expect(
          acceptedOptionIndices(
              ['খ', 'enjoy'], ['A', 'B', 'enjoy', 'D']),
          [1, 2]);
    });
    test('unmatched variants yield no indices', () {
      expect(acceptedOptionIndices(['zzz'], ['A', 'B']), isEmpty);
    });
    test('duplicates collapse and output is sorted', () {
      expect(
          acceptedOptionIndices(['ঘ', 'খ', 'ঘ'], ['A', 'B', 'C', 'D']),
          [1, 3]);
    });
  });

  group('isAcceptedOptionIndex', () {
    test('any listed variant earns full marks', () {
      expect(isAcceptedOptionIndex(3, [3, 8]), isTrue);
      expect(isAcceptedOptionIndex(8, [3, 8]), isTrue);
      expect(isAcceptedOptionIndex(0, [3, 8]), isFalse);
      expect(isAcceptedOptionIndex(0, []), isFalse);
    });
  });
}
