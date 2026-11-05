// English bucket (গল্প ও কবিতা) tests: unnamed poem/story
// rows only. No Edge, no I/O. Fake scan mirrors the reader
// screen test's fake.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/english_redesign.dart';
import 'package:yes_sir_ai/core/data/english_redesign_lessons.dart';
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
        String? lesson}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Question $id',
        questionType: section,
        section: section,
        stimulusText: text,
        stimulusRef: ref,
        setId: setId,
        lesson: lesson);

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

void main() {
  test('bucket membership: generic rows in, titled rows out', () {
    expect(isBucketPoemStoryRow('poem', 'textbook poems'), isTrue);
    expect(
        isBucketPoemStoryRow(
            'poem', 'Poems of textbook (Q8 set, main-19)'),
        isTrue);
    expect(isBucketPoemStoryRow('poem', 'Poem: Books'), isFalse);
    expect(isBucketPoemStoryRow('poem', null), isTrue);
    expect(isBucketPoemStoryRow('story', 'textbook stories'), isTrue);
    expect(
        isBucketPoemStoryRow(
            'story', 'Stories of textbook (Q9 set, main-19)'),
        isTrue);
    expect(isBucketPoemStoryRow('story', 'Story about Rosamond'),
        isFalse);
    expect(
        isBucketPoemStoryRow('story', 'Story: Merchant of Venice'),
        isFalse);
    expect(isBucketPoemStoryRow('mcq', 'textbook poems'), isFalse);
    // No overlap: a titled row matches its title entry too.
    expect(poemNameForRef('Poem: Books'), 'Books');
    expect(storyNameForRef('Story about Rosamond'), 'The Purple Jar');
  });

  test('bucket lesson items: tests, then lessons, then fallback',
      () {
    final rows = [
      q('a', section: 'poem', ref: 'textbook poems', setId: 'main-17'),
      q('b', section: 'story', ref: 'textbook stories', setId: 'main-17'),
      q('c', section: 'poem', ref: 'textbook poems', setId: 'main-10'),
      q('d', section: 'story', ref: 'textbook stories',
          setId: 'special1-57'),
      q('e', section: 'poem', ref: 'textbook poems',
          lesson: 'Unit-11; Lesson-7(A)'),
      q('f', section: 'story', ref: 'textbook stories',
          lesson: 'Unit-1; Lesson-1'),
      q('g', section: 'story', ref: 'textbook stories'),
      // Titled rows must not create items.
      q('h', section: 'poem', ref: 'Poem: Books', setId: 'main-17'),
    ];
    final items = bucketLessonItemsFromRows(rows);
    expect(items.map((i) => i.setId).toList(),
        ['main-10', 'main-17', 'special1-57', null, null, null]);
    expect(items.map((i) => i.lesson).toList(), [
      null,
      null,
      null,
      'Unit-1; Lesson-1',
      'Unit-11; Lesson-7(A)',
      null,
    ]);
    expect(bucketLessonLabel(items[1], true),
        'মডেল টেস্ট ১৭ · গল্প ও কবিতা');
    expect(bucketLessonLabel(items[2], true),
        'বিশেষ মডেল টেস্ট ১৪ · গল্প ও কবিতা');
    expect(bucketLessonLabel(items[5], false), 'Poem & Story');
    expect(
        redesignLessonDisplayLabel(items[0], true),
        'মডেল টেস্ট ১০ · গল্প ও কবিতা');
  });

  test('service bucket items come from set rows plus bank rows',
      () async {
    final service = EnglishReaderService(
        scan: fakeScan(
            sets: [
              GuideModelSetInfo(
                  setId: 'main-17', totalCount: 2, keyedCount: 0),
            ],
            setRows: {
              'main-17': [
                q('a', section: 'poem', ref: 'textbook poems',
                    setId: 'main-17'),
              ],
            },
            bankRows: [
              q('b', section: 'story', ref: 'textbook stories',
                  lesson: 'Unit-1; Lesson-1'),
            ]));
    final items = await service.bucketLessonItems(9);
    expect(items, isNotNull);
    expect(items!.length, 2);
    expect(items[0].setId, 'main-17');
    expect(items[1].lesson, 'Unit-1; Lesson-1');
  });

  testWidgets('bucket reader: honest note, one question, jump',
      (tester) async {
    languageNotifier.value = const Locale('bn');
    final rows = [
      q('b1', section: 'poem', ref: 'textbook poems', setId: 'main-17'),
      q('b2', section: 'poem', ref: 'textbook poems', setId: 'main-17'),
      q('b3', section: 'story', ref: 'textbook stories',
          setId: 'main-17'),
    ];
    await tester.pumpWidget(MaterialApp(
        home: EnglishReaderScreen(
      schoolClass: 9,
      kind: EnglishReaderKind.bucket,
      title: 'মডেল টেস্ট ১৭ · গল্প ও কবিতা',
      setId: 'main-17',
      readerService: EnglishReaderService(
          scan: fakeScan(
              sets: [
                GuideModelSetInfo(
                    setId: 'main-17', totalCount: 3, keyedCount: 0),
              ],
              setRows: {'main-17': rows})),
    )));
    await tester.pumpAndSettle();
    // No passage text on generic rows: honest note, never invented.
    expect(find.text('এই প্যাসেজের লেখা পাওয়া যায়নি'),
        findsOneWidget);
    // One sub-question at a time, poem group first.
    expect(find.text('Question b1'), findsOneWidget);
    expect(find.text('Question b2'), findsNothing);
    // Jump bar leaps to the story group in one tap. The taller
    // sticky passage box pushed the bar below the test fold, so
    // scroll it into view first.
    await tester.ensureVisible(find.text('Q9 · গল্প (যেকোনো ৫টি)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Q9 · গল্প (যেকোনো ৫টি)'));
    await tester.pumpAndSettle();
    expect(find.text('Question b3'), findsOneWidget);
    expect(find.text('Question b1'), findsNothing);
  });
}
