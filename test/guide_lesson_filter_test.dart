// Step 7 trim: the lesson/level/resolve/chips tests lived in
// this file tested the deleted old filter widgets
// (guide_lesson_filter, guide_bank_filter, guide_search_resolve).
// Only the intact-model test survives: stimulusText parsing
// tolerance + round-trip in GuideBankQuestion.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';

void main() {
  test('model parses stimulusText tolerantly, round-trips it', () {
    final bare = GuideBankQuestion.fromJson({
      'id': 'x',
      'questionText': 'q',
      'questionType': 'creative',
    });
    expect(bare.stimulusText, isNull);
    final serverBare = GuideBankQuestion.fromServerJson({
      'id': 'x',
      'questionText': 'q',
      'questionType': 'creative',
    });
    expect(serverBare.stimulusText, isNull);
    final tagged = GuideBankQuestion(
      id: 'c1',
      questionText: 'q',
      questionType: 'creative',
      stimulusId: 'cr-01',
      stimulusText: 'f(a) = ...',
    );
    expect(tagged.stimulusText, 'f(a) = ...');
    final rt = GuideBankQuestion.fromJson(tagged.toJson());
    expect(rt.stimulusText, 'f(a) = ...');
    expect(rt.stimulusId, 'cr-01');
  });
}
