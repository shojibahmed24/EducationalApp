// English redesign pure-logic tests (no Edge, no I/O).
// Covers strict lesson mapping, poem/story title matching with
// the real ref spellings found in the guide data, practice
// serials, passage selection and reader grouping.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/english_reader_shape.dart';
import 'package:yes_sir_ai/core/data/english_redesign.dart';
import 'package:yes_sir_ai/core/data/english_redesign_lessons.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';

GuideBankQuestion q(String id,
        {String? section,
        String? lesson,
        String? ref,
        String? text,
        String? setId}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Q $id',
        questionType: section ?? '',
        section: section,
        lesson: lesson,
        stimulusRef: ref,
        stimulusText: text,
        setId: setId);

GuideModelSetInfo set(String id) =>
    GuideModelSetInfo(setId: id, totalCount: 10, keyedCount: 1);

void main() {
  test('model items keep only main sets, sorted and numbered', () {
    final items = modelLessonItems([
      set('special1-44'),
      set('main-03'),
      set('board-2024'),
      set('main-01'),
      set('main-10'),
    ]);
    expect(items.map((e) => e.setId).toList(),
        ['main-01', 'main-03', 'main-10']);
    expect(items.map((e) => e.index).toList(), [1, 2, 3]);
    expect(items.every((e) => e.kind == 'model'), isTrue);
  });

  test('special items map 44 to 1 and sort by trailing number', () {
    final items = specialLessonItems(
        [set('special1-57'), set('main-01'), set('special1-44')]);
    expect(items.map((e) => e.setId).toList(),
        ['special1-44', 'special1-57']);
    expect(items.map((e) => e.index).toList(), [1, 2]);
  });

  test('poem matching covers every real ref spelling', () {
    expect(poemNameForRef('Poem: Books'), 'Books');
    expect(poemNameForRef("Poem 'Books' (textbook)"), 'Books');
    expect(poemNameForRef('textbook poem: Books'), 'Books');
    expect(poemNameForRef('Poem: Two Mothers Remembered'),
        'Two Mothers Remembered');
    expect(poemNameForRef('Poem: The Sands of Dee'), 'The Sands of Dee');
    expect(
        poemNameForRef('textbook poem: Solitude (word meanings)'),
        'Solitude');
    expect(poemNameForRef("Poem 'O me! O Life' (textbook)"),
        'O Me! O Life!');
    expect(poemNameForRef('Poem: Time, You Old Gipsy Man'),
        'Time, You Old Gipsy Man');
    expect(poemNameForRef('Poem: Stopping by Woods on a Snowy Evening'),
        'Stopping by Woods on a Snowy Evening');
  });

  test('poem matching never guesses a generic ref into a poem', () {
    expect(poemNameForRef('textbook poems'), isNull);
    expect(poemNameForRef('textbook poems (not printed on test page)'),
        isNull);
    expect(poemNameForRef('Poems of textbook (Q8 set, main-19)'), isNull);
    expect(poemNameForRef(null), isNull);
    expect(poemNameForRef(''), isNull);
  });

  test('story matching covers title variants and the Rosamond alias', () {
    expect(storyNameForRef('Story: The Purple Jar'), 'The Purple Jar');
    expect(storyNameForRef("Story 'The Purple Jar' (textbook)"),
        'The Purple Jar');
    expect(storyNameForRef('textbook story: The Purple Jar'),
        'The Purple Jar');
    expect(storyNameForRef('Story about Rosamond (textbook)'),
        'The Purple Jar');
    expect(storyNameForRef('Story: Merchant of Venice'),
        'Merchant of Venice');
    expect(storyNameForRef("Story 'The Merchant of Venice' (textbook)"),
        'Merchant of Venice');
    expect(storyNameForRef('textbook stories'), isNull);
    expect(
        storyNameForRef('textbook stories (not printed on test page)'),
        isNull);
  });

  test('practice serials group by lesson+ref in lesson order', () {
    final rows = [
      q('a', lesson: 'Unit-02; Lesson-01', ref: 'P2'),
      q('b', lesson: 'Unit-01; Lesson-01', ref: 'P1'),
      q('c', lesson: 'Unit-01; Lesson-01', ref: 'P1'),
      q('d', lesson: 'Unit-01; Lesson-01'), // passage-less
      q('e', ref: 'P9'), // lesson-free: never a serial
      q('f', lesson: 'Unit-10; Lesson-06', ref: 'P3'),
    ];
    final serials = practiceSerials(rows);
    expect(serials.length, 4);
    expect(serials[0].lesson, 'Unit-01; Lesson-01');
    expect(serials[0].stimulusRef, 'P1');
    expect(serials[1].stimulusRef, isNull); // passage-less trails
    expect(serials[2].lesson, 'Unit-02; Lesson-01');
    expect(serials[3].lesson, 'Unit-10; Lesson-06');
    expect(serials.map((s) => s.index).toList(), [1, 2, 3, 4]);
  });

  test('reader passage is the most-carried text, ties to longest', () {
    final rows = [
      q('a', ref: 'main', text: 'AAA'),
      q('b', ref: 'main', text: 'AAA'),
      q('c', ref: 'other', text: 'BBBBBBBB'),
    ];
    expect(readerPassage(rows), 'AAA');
    expect(
        readerPassage(
            [q('a', text: 'XX'), q('b', text: 'YYYY')]),
        'YYYY');
    expect(readerPassage([q('a'), q('b')]), isNull);
  });

  test('passage parts group three paragraphs, blank lines only', () {
    expect(splitPassageParts('one\n\ntwo\nthree'), ['one\n\ntwo\nthree']);
    expect(splitPassageParts('single'), ['single']);
    expect(
        splitPassageParts('p1\n\np2\n\np3\n\np4\n\np5\n\np6\n\np7'),
        ['p1\n\np2\n\np3', 'p4\n\np5\n\np6', 'p7']);
  });

  test('reader groups keep first-appearance order', () {
    final rows = [
      q('a', section: 'mcq'),
      q('b', section: 'mcq'),
      q('c', section: 'short'),
      q('d', section: 'mcq'), // joins the first group
    ];
    final groups = buildReaderGroups(rows, 'model');
    expect(groups.length, 2);
    expect(groups[0].questions.map((r) => r.id).toList(), ['a', 'b', 'd']);
    expect(groups[1].section, 'short');
  });

  test('real main-01 order: matching/rearranging arrive before table',
      () {
    // The server row order for main-01 is mcq, short, gapfill,
    // matching, rearranging, summary, table — the service must
    // re-sort test groups into Q1..Q7 order (see service).
    final rows = [
      q('a', section: 'mcq'),
      q('b', section: 'short'),
      q('c', section: 'gapfill'),
      q('d', section: 'matching'),
      q('e', section: 'rearranging'),
      q('f', section: 'summary'),
      q('g', section: 'table'),
    ];
    final groups = buildReaderGroups(rows, 'model');
    expect(groups.map((g) => g.section).toList(), [
      'mcq',
      'short',
      'gapfill',
      'matching',
      'rearranging',
      'summary',
      'table',
    ]);
    final sorted = groups.toList()
      ..sort((a, b) => englishPassageBasedSections
          .indexOf(a.section ?? '')
          .compareTo(
              englishPassageBasedSections.indexOf(b.section ?? '')));
    expect(sorted.map((g) => g.section).toList(), [
      'mcq',
      'short',
      'gapfill',
      'table',
      'summary',
      'matching',
      'rearranging',
    ]);
  });

  test('poem groups split by set, not by section', () {
    final rows = [
      q('a', section: 'poem', setId: 'main-01'),
      q('b', section: 'poem', setId: 'main-02'),
      q('c', section: 'poem'),
    ];
    final groups = buildReaderGroups(rows, 'poem');
    expect(groups.length, 3);
    expect(groups[2].setId, isNull);
  });

  test('test question labels map sections to Q1..Q7', () {
    expect(englishTestQuestionLabel('mcq'), 'Q1');
    expect(englishTestQuestionLabel('short'), 'Q2');
    expect(englishTestQuestionLabel('rearranging'), 'Q7');
    expect(englishTestQuestionLabel('poem'), isNull);
  });

  test('set display labels parse main and special ids', () {
    expect(setDisplayLabel('main-03', true), 'মডেল ৩');
    expect(setDisplayLabel('special1-44', true), 'বিশেষ ১');
    expect(setDisplayLabel('special1-57', false), 'Special 14');
    expect(setDisplayLabel(null, true), 'ব্যাংক');
  });

  test('redesign lesson labels use Bangla digits in Bangla', () {
    expect(redesignLessonLabel('model', 3, null, true), 'মডেল টেস্ট ৩');
    expect(redesignLessonLabel('model', 3, null, false), 'Model Test 3');
    expect(redesignLessonLabel('practice', 12, null, true),
        'পাঠ্যভিত্তিক অনুশীলনী ১২');
    expect(redesignLessonLabel('poem', 0, 'Books', true), 'Books');
  });
}
