// English reader widget tests (no Edge, no I/O).
// Fake scan data covers: a model test with a two-part
// passage (poem rows must be excluded), a practice serial
// where true-false comes first, and a passage-less set.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_reader_service.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';
import 'package:yes_sir_ai/features/learn/english_reader_screen.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

GuideBankQuestion q(String id,
        {required String section,
        String? text,
        String? ref,
        String? setId,
        String? lesson,
        List<String> options = const []}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Question $id',
        questionType: section,
        section: section,
        stimulusText: text,
        stimulusRef: ref,
        setId: setId,
        lesson: lesson,
        options: options);

EnglishSetScanService fakeScan({
  List<GuideModelSetInfo>? sets,
  Map<String, List<GuideBankQuestion>>? setRows,
  List<GuideBankQuestion>? bankRows,
}) =>
    EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => sets,
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async =>
          setRows?[setId],
      fetchBankRows: (subject, {int schoolClass = 9}) async => bankRows,
    );

Future<void> pumpReader(WidgetTester tester, Widget screen) async {
  languageNotifier.value = const Locale('bn');
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  final passage = 'Para one.\n\nPara two.\n\nPara three.\n\nPara four.';
  final modelRows = [
    q('m1', section: 'mcq', text: passage, ref: 'P', setId: 'main-01',
        options: ['A', 'B']),
    q('m2', section: 'mcq', text: passage, ref: 'P', setId: 'main-01',
        options: ['C', 'D']),
    q('s1', section: 'short', text: passage, ref: 'P', setId: 'main-01'),
    q('g1', section: 'gapfill', text: passage, ref: 'P', setId: 'main-01'),
    q('p1', section: 'poem', text: 'Poem text', setId: 'main-01'),
  ];

  Widget modelScreen() => EnglishReaderScreen(
        schoolClass: 9,
        kind: EnglishReaderKind.model,
        title: 'মডেল টেস্ট ১',
        setId: 'main-01',
        readerService: EnglishReaderService(
            scan: fakeScan(
                sets: [GuideModelSetInfo(
                    setId: 'main-01', totalCount: 5, keyedCount: 0)],
                setRows: {'main-01': modelRows})),
      );

  testWidgets('model reader: sticky passage, one question, jump',
      (tester) async {
    await pumpReader(tester, modelScreen());
    // Passage box shows the first part; poem rows excluded.
    expect(find.text('Para one.\n\nPara two.\n\nPara three.'),
        findsOneWidget);
    expect(find.text('Q8'), findsNothing);
    // Jump bar always visible with test groups only.
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('Q2'), findsOneWidget);
    expect(find.text('Q3'), findsOneWidget);
    // First sub-question only.
    expect(find.text('Q1 · ১'), findsOneWidget);
    expect(find.text('Question m2'), findsNothing);
    // Next advances within the group; passage stays put.
    await tester.ensureVisible(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    expect(find.text('Q1 · ২'), findsOneWidget);
    expect(find.text('Para one.\n\nPara two.\n\nPara three.'),
        findsOneWidget);
    // Next again crosses into Q2.
    await tester.ensureVisible(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    expect(find.text('Q2 · ১'), findsOneWidget);
    // Jump bar leaps to Q3's first part in one tap. The taller
    // sticky passage box pushed the bar below the test fold, so
    // scroll it into view first (same as the Q3 passage test).
    await tester.ensureVisible(find.text('Q3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Q3'));
    await tester.pumpAndSettle();
    expect(find.text('Q3 · ১'), findsOneWidget);
    // Past the last question: the end card.
    await tester.ensureVisible(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('পরবর্তী প্রশ্ন'));
    await tester.pumpAndSettle();
    expect(find.text('এই সেট শেষ'), findsOneWidget);
  });

  testWidgets('model reader: passage parts page inside the box',
      (tester) async {
    await pumpReader(tester, modelScreen());
    expect(find.text('Para one.\n\nPara two.\n\nPara three.'),
        findsOneWidget);
    await tester.tap(find.text('পরবর্তী'));
    await tester.pumpAndSettle();
    expect(find.text('Para four.'), findsOneWidget);
    expect(find.text('Q1 · ১'), findsOneWidget);
  });

  testWidgets('reader box follows the current question passage',
      (tester) async {
    final rows = [
      q('m1', section: 'mcq', text: 'Shyam one.\n\nShyam two.',
          ref: 'S', setId: 'main-11', options: ['A', 'B']),
      q('g1', section: 'gapfill', text: 'Nepal one.\n\nNepal two.',
          ref: 'N', setId: 'main-11'),
    ];
    await pumpReader(
        tester,
        EnglishReaderScreen(
          schoolClass: 9,
          kind: EnglishReaderKind.model,
          title: 'মডেল টেস্ট ১১',
          setId: 'main-11',
          readerService: EnglishReaderService(
              scan: fakeScan(
                  sets: [
                    GuideModelSetInfo(
                        setId: 'main-11', totalCount: 2, keyedCount: 0)
                  ],
                  setRows: {'main-11': rows})),
        ));
    expect(find.text('Shyam one.\n\nShyam two.'), findsOneWidget);
    // Nav sits at the page end (user order), so it starts below
    // the test viewport fold: scroll it into view before tapping.
    await tester.ensureVisible(find.text('Q3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Q3'));
    await tester.pumpAndSettle();
    expect(find.text('Nepal one.\n\nNepal two.'), findsOneWidget);
    expect(find.text('Shyam one.\n\nShyam two.'), findsNothing);
  });

  testWidgets('practice reader keeps exercise order, true-false first',
      (tester) async {
    final bank = [
      q('t1', section: 'true-false', text: 'Lesson passage',
          ref: 'LP', lesson: 'Unit-10; Lesson-06'),
      q('m1', section: 'mcq', text: 'Lesson passage', ref: 'LP',
          lesson: 'Unit-10; Lesson-06', options: ['A', 'B']),
    ];
    await pumpReader(
        tester,
        EnglishReaderScreen(
          schoolClass: 9,
          kind: EnglishReaderKind.practice,
          title: 'পাঠ্যভিত্তিক অনুশীলনী ১',
          lesson: 'Unit-10; Lesson-06',
          stimulusRef: 'LP',
          readerService: EnglishReaderService(
              scan: fakeScan(bankRows: bank)),
        ));
    expect(find.text('True/False · ১'), findsOneWidget);
    expect(find.text('Question t1'), findsOneWidget);
  });

  testWidgets('passage-less set shows the honest note, not invented text',
      (tester) async {
    await pumpReader(
        tester,
        EnglishReaderScreen(
          schoolClass: 9,
          kind: EnglishReaderKind.model,
          title: 'মডেল টেস্ট ১',
          setId: 'main-01',
          readerService: EnglishReaderService(
              scan: fakeScan(
                  sets: [GuideModelSetInfo(
                      setId: 'main-01', totalCount: 1, keyedCount: 0)],
                  setRows: {
                    'main-01': [q('m1', section: 'mcq', options: ['A'])]
                  })),
        ));
    expect(find.text('এই প্যাসেজের লেখা পাওয়া যায়নি'),
        findsOneWidget);
    expect(find.text('Q1 · ১'), findsOneWidget);
  });
}
