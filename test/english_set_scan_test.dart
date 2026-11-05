// English set-scan tests (separate English search flow).
// No Edge, no I/O: fake sets/rows only. Covers section and
// lesson filtering over set rows, pagination with resume,
// unavailable states, lesson discovery, and the redirect
// predicate that keeps Math on the old flow.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';

GuideBankQuestion _q(String id, String? section, String? lesson) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Q $id',
        questionType: section ?? '',
        section: section,
        lesson: lesson,
        setId: 'set-a');

GuideModelSetInfo _set(String id, int total) =>
    GuideModelSetInfo(setId: id, totalCount: total, keyedCount: 0);

class _Fake {
  _Fake({required this.sets, required this.rows});
  final List<GuideModelSetInfo>? sets;
  final Map<String, List<GuideBankQuestion>> rows;
  final Set<String> failedSets = {};
  int setRowsCalls = 0;

  Future<List<GuideModelSetInfo>?> fetchSets(String subject,
      {int schoolClass = 9}) async {
    return sets;
  }

  Future<List<GuideBankQuestion>?> fetchSetRows(String subject, String setId,
      {int schoolClass = 9}) async {
    setRowsCalls++;
    if (failedSets.contains(setId)) return null;
    return rows[setId];
  }

  /// These tests predate the bank phase: empty bank rows
  /// keep their set-only expectations intact.
  Future<List<GuideBankQuestion>?> fetchBankRows(String subject,
      {int schoolClass = 9}) async {
    return const <GuideBankQuestion>[];
  }
}

void main() {
  test('section filter scans sets in order with resume pagination', () async {
    final rowsA = [
      for (var i = 0; i < 15; i++) _q('a-mcq-$i', 'mcq', null),
      _q('a-poem-0', 'poem', null),
    ];
    final rowsB = [
      for (var i = 0; i < 10; i++) _q('b-mcq-$i', 'mcq', null),
    ];
    final fake = _Fake(
        sets: [_set('set-a', 16), _set('set-b', 10)],
        rows: {'set-a': rowsA, 'set-b': rowsB});
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final first = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq');
    expect(first.rows.length, 20);
    expect(first.hasMore, isTrue);
    expect(first.unavailable, isFalse);
    expect(first.rows.first.id, 'a-mcq-0');
    expect(first.rows.last.id, 'b-mcq-4');
    final second = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq', resume: first.nextCursor);
    expect(second.rows.length, 5);
    expect(second.hasMore, isFalse);
    expect(second.rows.last.id, 'b-mcq-9');
  });

  test('lesson filter and section+lesson filter combine', () async {
    final rows = [
      _q('r1', 'mcq', 'Unit-01; Lesson-01'),
      _q('r2', 'mcq', 'Unit-02; Lesson-01'),
      _q('r3', 'poem', 'Unit-01; Lesson-01'),
    ];
    final fake = _Fake(
        sets: [_set('set-a', 3)], rows: {'set-a': rows});
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final byLesson = await scan.fetchFilteredPage(
        schoolClass: 9, lesson: 'Unit-01; Lesson-01');
    expect(byLesson.rows.map((r) => r.id), ['r1', 'r3']);
    final both = await scan.fetchFilteredPage(
        schoolClass: 9,
        section: 'mcq',
        lesson: 'Unit-01; Lesson-01');
    expect(both.rows.map((r) => r.id), ['r1']);
  });

  test('set page pages locally; first-page failure is unavailable', () async {
    final rows = [for (var i = 0; i < 25; i++) _q('s-$i', 'mcq', null)];
    final fake = _Fake(
        sets: [_set('set-a', 25)], rows: {'set-a': rows});
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final first =
        await scan.fetchSetPage(schoolClass: 9, setId: 'set-a');
    expect(first.rows.length, 20);
    expect(first.hasMore, isTrue);
    final second = await scan.fetchSetPage(
        schoolClass: 9, setId: 'set-a', offset: 20);
    expect(second.rows.length, 5);
    expect(second.hasMore, isFalse);
    final failing = EnglishSetScanService(
        fetchSets: fake.fetchSets,
        fetchSetRows: (_, __, {int schoolClass = 9}) async => null);
    final bad = await failing.fetchSetPage(schoolClass: 9, setId: 'set-a');
    expect(bad.unavailable, isTrue);
    expect(bad.rows, isEmpty);
  });

  test('mid-scan failure returns matched rows with retry cursor', () async {
    final fake = _Fake(
        sets: [_set('set-a', 2), _set('set-b', 2)],
        rows: {
          'set-a': [_q('a1', 'mcq', null), _q('a2', 'mcq', null)],
          'set-b': [_q('b1', 'mcq', null)],
        });
    fake.failedSets.add('set-b');
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final page = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq');
    expect(page.rows.map((r) => r.id), ['a1', 'a2']);
    expect(page.hasMore, isTrue);
    expect(page.nextCursor?.setIndex, 1);
    expect(page.unavailable, isFalse);
  });

  test('lesson discovery is distinct, sorted, and cached', () async {
    final fake = _Fake(
        sets: [_set('set-a', 3), _set('set-b', 2)],
        rows: {
          'set-a': [
            _q('a1', 'mcq', 'Unit-02; Lesson-01'),
            _q('a2', 'mcq', 'Unit-01; Lesson-01'),
            _q('a3', 'mcq', 'Unit-02; Lesson-01'),
          ],
          'set-b': [
            _q('b1', 'mcq', 'Unit-01; Lesson-01'),
            _q('b2', 'mcq', null),
          ],
        });
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final lessons = await scan.fetchLessons(schoolClass: 9);
    expect(lessons, ['Unit-01; Lesson-01', 'Unit-02; Lesson-01']);
    final callsAfterFirst = fake.setRowsCalls;
    await scan.fetchLessons(schoolClass: 9);
    expect(fake.setRowsCalls, callsAfterFirst);
  });

  test('unreachable sets server is unavailable, not empty', () async {
    final fake = _Fake(sets: null, rows: {});
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    final page = await scan.fetchFilteredPage(
        schoolClass: 9, section: 'mcq');
    expect(page.unavailable, isTrue);
    expect(page.rows, isEmpty);
    expect(await scan.fetchLessons(schoolClass: 9), isNull);
  });

  test('lesson discovery failure is unavailable, not partial', () async {
    final fake = _Fake(sets: [_set('set-a', 1)], rows: {});
    fake.failedSets.add('set-a');
    final scan = EnglishSetScanService(
        fetchSets: fake.fetchSets, fetchSetRows: fake.fetchSetRows,
        fetchBankRows: fake.fetchBankRows);
    expect(await scan.fetchLessons(schoolClass: 9), isNull);
  });

  test('redirect predicate: only English guide uses the new flow', () {
    expect(shouldUseEnglishSearchFlow('english', 'guide'), isTrue);
    expect(shouldUseEnglishSearchFlow('math', 'guide'), isFalse);
    expect(shouldUseEnglishSearchFlow('english', 'textbook'), isFalse);
    expect(shouldUseEnglishSearchFlow('math', 'textbook'), isFalse);
    expect(shouldUseEnglishSearchFlow('science', 'guide'), isFalse);
  });
}
