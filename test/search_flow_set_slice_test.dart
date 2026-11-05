// Set lists page by WHOLE stimulus groups: a group straddling
// the 20-row budget comes through whole, never split.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/search_flow_set_slice.dart';

GuideBankQuestion q(String id, {String? sid}) => GuideBankQuestion(
  id: id,
  questionText: 'q $id',
  questionType: sid == null ? 'mcq' : 'creative',
  stimulusId: sid,
);

void main() {
  test('group straddling the budget comes through whole', () {
    final rows = [
      for (var i = 1; i <= 19; i++) q('m$i'),
      q('c1', sid: 's1'),
      q('c2', sid: 's1'),
      q('c3', sid: 's1'),
      q('m20'),
    ];
    final shown = visibleSetRows(rows, 20);
    // 19 singletons + the whole 3-part group = 22 rows, not 20.
    expect(shown.length, 22);
    expect(shown.map((r) => r.id), [
      ...List.generate(19, (i) => 'm${i + 1}'),
      'c1',
      'c2',
      'c3',
    ]);
  });
  test('budget beyond total returns everything, in order', () {
    final rows = [q('a', sid: 's1'), q('b', sid: 's1'), q('c')];
    expect(visibleSetRows(rows, 20).map((r) => r.id), ['a', 'b', 'c']);
  });
  test('empty set returns empty', () {
    expect(visibleSetRows([], 20), isEmpty);
  });
  test('first group always included even if it exceeds budget', () {
    final rows = [q('c1', sid: 's1'), q('c2', sid: 's1'), q('m1')];
    expect(visibleSetRows(rows, 1).map((r) => r.id), ['c1', 'c2']);
  });
}
