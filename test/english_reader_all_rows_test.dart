// Poem/story aggregation tests (2026-11-03): the poem open
// used to fire 100+ sequential paged calls (57 sets + a
// 1,556-row bank at 50 rows a page), so poem screens sat on
// the spinner. Aggregation now batches set fetches and stays
// fail-closed. No Edge, no I/O — fake scan with counters.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_reader_service.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';

GuideBankQuestion q(String id,
        {required String section,
        String? ref,
        String? setId}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Question $id',
        questionType: section,
        section: section,
        stimulusRef: ref,
        setId: setId);

void main() {
  test('poem load fetches every set once plus the bank', () async {
    var setCalls = 0;
    var bankCalls = 0;
    final scan = EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => [
        GuideModelSetInfo(setId: 'main-01', totalCount: 2, keyedCount: 0),
        GuideModelSetInfo(setId: 'main-02', totalCount: 1, keyedCount: 0),
      ],
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async {
        setCalls++;
        return {
          'main-01': [
            q('p1', section: 'poem', ref: 'Poem: Books', setId: 'main-01'),
            q('m1', section: 'mcq', setId: 'main-01'),
          ],
          'main-02': [
            q('p2', section: 'poem', ref: 'Poem: Books', setId: 'main-02'),
          ],
        }[setId];
      },
      fetchBankRows: (subject, {int schoolClass = 9}) async {
        bankCalls++;
        return [
          q('p3', section: 'poem', ref: 'Poem: Books'),
          q('p4', section: 'poem', ref: 'Poem: Solitude'),
        ];
      },
    );
    final data = await EnglishReaderService(scan: scan).load(
        const EnglishReaderRequest(
            kind: EnglishReaderKind.poem,
            schoolClass: 9,
            workName: 'Books'));
    expect(data, isNotNull);
    expect(data!.totalQuestions, 3);
    expect(data.groups.length, 3);
    expect(setCalls, 2);
    expect(bankCalls, 1);
  });

  test('poem load fails closed when any set fetch fails', () async {
    final scan = EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => [
        GuideModelSetInfo(setId: 'main-01', totalCount: 1, keyedCount: 0),
        GuideModelSetInfo(setId: 'main-02', totalCount: 1, keyedCount: 0),
      ],
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async =>
          setId == 'main-01'
              ? [q('p1', section: 'poem', ref: 'Poem: Books')]
              : null,
      fetchBankRows: (subject, {int schoolClass = 9}) async => [],
    );
    final data = await EnglishReaderService(scan: scan).load(
        const EnglishReaderRequest(
            kind: EnglishReaderKind.poem,
            schoolClass: 9,
            workName: 'Books'));
    expect(data, isNull);
  });

  test('poem load fails closed when the bank fetch fails', () async {
    final scan = EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => [
        GuideModelSetInfo(setId: 'main-01', totalCount: 1, keyedCount: 0),
      ],
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async =>
          [q('p1', section: 'poem', ref: 'Poem: Books')],
      fetchBankRows: (subject, {int schoolClass = 9}) async => null,
    );
    final data = await EnglishReaderService(scan: scan).load(
        const EnglishReaderRequest(
            kind: EnglishReaderKind.poem,
            schoolClass: 9,
            workName: 'Books'));
    expect(data, isNull);
  });
}
