// Guide-quiz guards (pure, offline): key-letter mapping, the
// scorable-pool filter (unkeyed + guide-error rows can never
// enter a scored quiz), and the free-open gate sentinel.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_bank_service.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_pool.dart';

GuideBankQuestion _row({
  required String id,
  String type = 'mcq',
  bool hasKey = true,
  List<String> options = const ['A', 'B', 'C', 'D'],
  String? setId,
}) =>
    GuideBankQuestion(
      id: id,
      questionText: 'q',
      questionType: type,
      options: options,
      serverHasKey: hasKey,
      setId: setId,
    );

void main() {
  group('guideKeyIndex', () {
    test('maps ক/খ/গ/ঘ/ঙ to 0..4 in Edge order', () {
      expect(guideKeyIndex('ক', 4), 0);
      expect(guideKeyIndex('খ', 4), 1);
      expect(guideKeyIndex('গ', 4), 2);
      expect(guideKeyIndex('ঘ', 4), 3);
      expect(guideKeyIndex('ঙ', 5), 4);
    });
    test('unknown letter or out-of-range index is null, never guessed', () {
      expect(guideKeyIndex('X', 4), null);
      expect(guideKeyIndex('', 4), null);
      expect(guideKeyIndex('ঘ', 2), null);
      expect(guideKeyIndex('ঙ', 4), null);
    });
  });

  group('isScorableGuideMcq', () {
    test('keyed MCQ with options is scorable', () {
      expect(isScorableGuideMcq(_row(id: 'ok-1')), isTrue);
    });
    test('unkeyed rows never enter the pool', () {
      expect(isScorableGuideMcq(_row(id: 'u-1', hasKey: false)), isFalse);
    });
    test('non-MCQ rows never enter the pool', () {
      expect(isScorableGuideMcq(_row(id: 'c-1', type: 'creative')), isFalse);
      expect(isScorableGuideMcq(_row(id: 'p-1', type: 'problem')), isFalse);
    });
    test('rows without options never enter the pool', () {
      expect(isScorableGuideMcq(_row(id: 'e-1', options: [])), isFalse);
    });
    test('model-test set rows never enter the daily/practice pool', () {
      expect(
          isScorableGuideMcq(
              _row(id: 'pilot0-mcq-1', setId: 'model-test-01')),
          isFalse);
    });
    test('all 18 known guide-error ids are excluded', () {
      expect(knownGuideErrorIds.length, 18);
      for (final id in knownGuideErrorIds) {
        expect(isScorableGuideMcq(_row(id: id)), isFalse,
            reason: 'guide-error id must never score: $id');
      }
    });
  });

  group('free-open gate', () {
    test('negative freeLimit unlocks every index for free users', () {
      expect(
          guideBankService.isUnlocked(
              isPremium: false, index: 9999, freeLimit: -1),
          isTrue);
    });
    test('zero freeLimit locks everything for free users', () {
      expect(
          guideBankService.isUnlocked(
              isPremium: false, index: 0, freeLimit: 0),
          isFalse);
    });
    test('premium still unlocks regardless of the limit', () {
      expect(
          guideBankService.isUnlocked(
              isPremium: true, index: 9999, freeLimit: 0),
          isTrue);
    });
  });
}
