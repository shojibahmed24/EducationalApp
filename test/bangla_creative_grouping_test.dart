// Pure-logic tests: creative grouping by stimulusId.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/bangla_creative_grouping.dart';

GuideBankQuestion q(String id, {String? sid, String? stim}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'q $id',
        questionType: 'creative',
        stimulusId: sid,
        stimulusText: stim);

void main() {
  test('same stimulusId => one group, parts preserved in order', () {
    final groups = groupBanglaCreative([
      q('1', sid: 's1', stim: 'stim'),
      q('2', sid: 's1'),
      q('3', sid: 's2', stim: 'other'),
    ]);
    expect(groups.length, 2);
    expect(groups[0].parts.map((e) => e.id), ['1', '2']);
    expect(groups[0].stimulusText, 'stim');
    expect(groups[1].parts.map((e) => e.id), ['3']);
  });

  test('empty stimulusId rows stand alone, never merged', () {
    final groups = groupBanglaCreative([q('1'), q('2'), q('3', sid: 's1')]);
    expect(groups.length, 3);
    expect(groups.map((g) => g.parts.length), [1, 1, 1]);
  });

  test('group stimulus falls back to a later non-empty part text', () {
    final groups = groupBanglaCreative(
        [q('1', sid: 's1'), q('2', sid: 's1', stim: 'found')]);
    expect(groups.length, 1);
    expect(groups[0].stimulusText, 'found');
  });

  test('empty input => no groups', () {
    expect(groupBanglaCreative([]), isEmpty);
  });
}
