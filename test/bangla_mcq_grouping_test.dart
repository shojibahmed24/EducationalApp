// Pure-logic tests: MCQ grouping incl. the untagged fallback.
// Grouping never crashes and never hides a row, whatever tags
// the server sends (all tagged / all untagged / mixed / unknown).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/bangla_mcq_grouping.dart';

GuideBankQuestion q(String id, {String? group}) => GuideBankQuestion(
    id: id, questionText: 'q $id', questionType: 'mcq', mcqGroup: group);

void main() {
  test('all tagged rows split into writer + lesson groups', () {
    final g = groupBanglaMcqs(
        [q('1', group: 'writer'), q('2', group: 'lesson')]);
    expect(g.hasTags, true);
    expect(g.writer.map((e) => e.id), ['1']);
    expect(g.lesson.map((e) => e.id), ['2']);
    expect(g.untagged, isEmpty);
    expect(g.total, 2);
  });

  test('all untagged rows => flat full list, nothing hidden', () {
    final g = groupBanglaMcqs([q('1'), q('2'), q('3')]);
    expect(g.hasTags, false);
    expect(g.untagged.map((e) => e.id), ['1', '2', '3']);
    expect(g.total, 3);
  });

  test('mixed tags keep untagged rows visible in their own bucket', () {
    final g = groupBanglaMcqs(
        [q('1', group: 'writer'), q('2'), q('3', group: 'lesson')]);
    expect(g.hasTags, true);
    expect(g.hasUntagged, true);
    expect(g.writer.map((e) => e.id), ['1']);
    expect(g.lesson.map((e) => e.id), ['3']);
    expect(g.untagged.map((e) => e.id), ['2']);
    expect(g.total, 3);
  });

  test('unknown tag values land in untagged, never crash', () {
    final g = groupBanglaMcqs([q('1', group: 'bogus')]);
    expect(g.hasTags, false);
    expect(g.untagged.map((e) => e.id), ['1']);
  });

  test('empty input => empty groups', () {
    final g = groupBanglaMcqs([]);
    expect(g.hasTags, false);
    expect(g.total, 0);
  });
}
