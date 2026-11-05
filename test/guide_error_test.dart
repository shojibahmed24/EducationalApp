import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_service.dart';

GuideBankQuestion mcq(String id, {bool guideError = false}) =>
    GuideBankQuestion(
      id: id,
      questionText: 'q',
      questionType: 'mcq',
      options: ['ক-অপশন', 'খ-অপশন'],
      serverHasKey: true,
      guideError: guideError,
    );

void main() {
  test('clean MCQ is scorable', () {
    expect(isScorableGuideMcq(mcq('x-mcq-1')), isTrue);
  });

  test('server-flagged guideError row is never scorable', () {
    expect(isScorableGuideMcq(mcq('x-mcq-2', guideError: true)), isFalse);
  });

  test('hardcoded 18 ids still excluded without a server flag', () {
    for (final id in knownGuideErrorIds) {
      expect(isScorableGuideMcq(mcq(id)), isFalse, reason: id);
    }
    expect(knownGuideErrorIds.length, 18);
  });

  test('fromServerJson parses guideError, defaults false when absent', () {
    final flagged = GuideBankQuestion.fromServerJson({
      'id': 'a',
      'questionText': 'q',
      'questionType': 'mcq',
      'options': ['ক', 'খ'],
      'hasKey': true,
      'guideError': true,
    });
    expect(flagged.guideError, isTrue);
    final absent = GuideBankQuestion.fromServerJson({
      'id': 'b',
      'questionText': 'q',
      'questionType': 'mcq',
      'options': ['ক', 'খ'],
      'hasKey': true,
    });
    expect(absent.guideError, isFalse);
    // Cache round-trip preserves the flag.
    final restored =
        GuideBankQuestion.fromJson(flagged.toJson());
    expect(restored.guideError, isTrue);
  });
}
