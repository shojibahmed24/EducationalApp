// English bank-phase tests (chapterless bank rows, 2026-11-01).
// No Edge, no I/O: fake sets/set rows/bank rows only. Covers
// set+bank merge order, resume crossing into the bank phase,
// bank-failure retry cursor without duplication, lesson union
// across both phases, and unavailable (never partial) states.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';

GuideBankQuestion _q(String id, String? section, String? lesson,
        {String? setId}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Q $id',
        questionType: section ?? '',
        section: section,
        lesson: lesson,
        setId: setId);

GuideModelSetInfo _set(String id, int total) =>
    GuideModelSetInfo(setId: id, totalCount: total, keyedCount: 0);

class _Fake {
  _Fake({required this.sets, required this.rows, required this.bank});
  final List<GuideModelSetInfo>? sets;
  final Map<String, List<GuideBankQuestion>> rows;
  final List<GuideBankQuestion>? bank;
  bool bankFailed = false;

  Future<List<GuideModelSetInfo>?> fetchSets(String subject,
      {int schoolClass = 9}) async {
    return sets;
  }

  Future<List<GuideBankQuestion>?> fetchSetRows(String subject, String setId,
      {int schoolClass = 9}) async {
    return rows[setId];
  }

  Future<List<GuideBankQuestion>?> fetchBankRows(String subject,
      {int schoolClass = 9}) async {
    if (bankFailed) return null;
    return bank;
  }
}

EnglishSetScanService _scan(_Fake fake) => EnglishSetScanService(
    fetchSets: fake.fetchSets,
    fetchSetRows: fake.fetchSetRows,
    fetchBankRows: fake.fetchBankRows);

void main() {
  test('section filter merges set rows then bank rows, resume crosses phase',
      () async {
    final fake = _Fake(
        sets: [_set('set-a', 18)],
        rows: {
          'set-a': [for (var i = 0; i < 18; i++) _q('s-$i', 'mcq', null, setId: 'set-a')],
        },
        bank: [for (var i = 0; i < 5; i++) _q('b-$i', 'mcq', null)]);
    final scan = _scan(fake);
    final first =
        await scan.fetchFilteredPage(schoolClass: 9, section: 'mcq');
    expect(first.rows.length, 20);
    expect(first.rows.take(18).map((r) => r.id),
        [for (var i = 0; i < 18; i++) 's-$i']);
    expect(first.rows.skip(18).map((r) => r.id), ['b-0', 'b-1']);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor?.inBank, isTrue);
    final second = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq', resume: first.nextCursor);
    expect(second.rows.map((r) => r.id), ['b-2', 'b-3', 'b-4']);
    expect(second.hasMore, isFalse);
    expect(second.nextCursor, isNull);
  });

  test('bank failure returns set matches with bank retry cursor, no duplicates',
      () async {
    final fake = _Fake(
        sets: [_set('set-a', 2)],
        rows: {
          'set-a': [
            _q('s-1', 'mcq', null, setId: 'set-a'),
            _q('s-2', 'mcq', null, setId: 'set-a'),
          ],
        },
        bank: [_q('b-1', 'mcq', null)]);
    fake.bankFailed = true;
    final scan = _scan(fake);
    final first =
        await scan.fetchFilteredPage(schoolClass: 9, section: 'mcq');
    expect(first.rows.map((r) => r.id), ['s-1', 's-2']);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor?.inBank, isTrue);
    expect(first.nextCursor?.bankRowIndex, 0);
    fake.bankFailed = false;
    final retry = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq', resume: first.nextCursor);
    expect(retry.rows.map((r) => r.id), ['b-1']);
    expect(retry.hasMore, isFalse);
  });

  test('first-page bank failure with no set matches is unavailable', () async {
    final fake = _Fake(
        sets: [_set('set-a', 1)],
        rows: {
          'set-a': [_q('s-1', 'poem', null, setId: 'set-a')],
        },
        bank: [_q('b-1', 'mcq', null)]);
    fake.bankFailed = true;
    final scan = _scan(fake);
    final page =
        await scan.fetchFilteredPage(schoolClass: 9, section: 'mcq');
    expect(page.unavailable, isTrue);
    expect(page.rows, isEmpty);
  });

  test('lesson union includes bank-only lessons, distinct and sorted',
      () async {
    final fake = _Fake(
        sets: [_set('set-a', 2)],
        rows: {
          'set-a': [
            _q('s-1', 'mcq', 'Unit-02; Lesson-01', setId: 'set-a'),
            _q('s-2', 'mcq', 'Unit-02; Lesson-01', setId: 'set-a'),
          ],
        },
        bank: [
          _q('b-1', 'mcq', 'Unit-01; Lesson-01'),
          _q('b-2', 'mcq', 'Unit-02; Lesson-01'),
        ]);
    final scan = _scan(fake);
    expect(await scan.fetchLessons(schoolClass: 9),
        ['Unit-01; Lesson-01', 'Unit-02; Lesson-01']);
  });

  test('bank failure makes lesson discovery unavailable, not partial',
      () async {
    final fake = _Fake(
        sets: [_set('set-a', 1)],
        rows: {
          'set-a': [_q('s-1', 'mcq', 'Unit-02; Lesson-01', setId: 'set-a')],
        },
        bank: [_q('b-1', 'mcq', 'Unit-01; Lesson-01')]);
    fake.bankFailed = true;
    final scan = _scan(fake);
    expect(await scan.fetchLessons(schoolClass: 9), isNull);
  });
}
