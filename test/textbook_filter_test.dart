// Worker A tests: textbook filter taxonomy + bar (NOT the guide
// bank filter: no marks / important chips exist here).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/textbook_chapter_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/textbook_filter.dart';
import 'package:yes_sir_ai/l10n/pages/chapter_questions_strings.dart';

TextbookChapterQuestion r(
  String id,
  String text,
  int page,
  int? problem,
  String? type,
) =>
    TextbookChapterQuestion(
      id: id,
      questionText: text,
      page: page,
      problem: problem,
      questionType: type,
    );

void main() {
  final all = [
    r('m1', 'বাগান MCQ', 10, 1, 'mcq'),
    r('m2', 'MCQ two', 10, 2, 'mcq'),
    r('s1', 'Short one', 11, 1, 'short'),
    r('u1', 'বাগান untyped', 12, null, null),
    r('u2', 'Essay kind', 12, 1, 'essay'),
    r('t1', 'Task one', 13, 1, 'task'),
  ];

  test('taxonomy: unknown + null -> other, known keys pass through', () {
    expect(textbookTypeKey(null), 'other');
    expect(textbookTypeKey('essay'), 'other');
    expect(textbookTypeKey(''), 'other');
    for (final k in ['mcq', 'fill_blank', 'creative', 'short', 'problem', 'task']) {
      expect(textbookTypeKey(k), k);
    }
  });

  test('present types are dynamic: only types in the chapter, counted', () {
    expect(textbookPresentTypes(all), [
      ('mcq', 2),
      ('short', 1),
      ('task', 1),
      ('other', 2),
    ]);
  });

  test('other chip label states it includes no-recorded-type rows', () {
    expect(chapterQuestionsStringsBn['typeOther']!,
        contains('ধরন লেখা নেই'));
    expect(chapterQuestionsStringsEn['typeOther']!,
        contains('no recorded type'));
  });

  test('filters combine with AND: type + text + page', () {
    List<String> ids({String type = 'all', String q = '', int? page}) =>
        filterTextbookQuestions(all: all, type: type, query: q, page: page)
            .map((e) => e.id)
            .toList();
    expect(ids(type: 'mcq', q: 'বাগান', page: 10), ['m1']);
    expect(ids(q: 'বাগান'), ['m1', 'u1']);
    expect(ids(page: 12), ['u1', 'u2']);
    expect(ids(type: 'other'), ['u1', 'u2']);
    expect(ids(type: 'other', page: 12, q: 'বাগান'), ['u1']);
    expect(ids(), ['m1', 'm2', 's1', 'u1', 'u2', 't1']);
  });

  testWidgets('bar shows only present type chips with counts',
      (tester) async {
    var selected = 'all';
    var query = '';
    var page = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TextbookFilterBar(
          s: chapterQuestionsStringsBn,
          presentTypes: const [('mcq', 5), ('other', 16)],
          selectedType: selected,
          onTypeChanged: (v) => selected = v,
          onQueryChanged: (v) => query = v,
          onPageChanged: (v) => page = v,
        ),
      ),
    ));
    expect(find.text('বহুনির্বাচনি (5)'), findsOneWidget);
    expect(find.text('অন্যান্য (ধরন লেখা নেই এমন প্রশ্নসহ) (16)'),
        findsOneWidget);
    expect(find.textContaining('সৃজনশীল'), findsNothing);
    await tester.tap(find.text('বহুনির্বাচনি (5)'));
    expect(selected, 'mcq');
    await tester.enterText(find.byType(TextField).first, 'বাগান');
    expect(query, 'বাগান');
    await tester.enterText(find.byType(TextField).at(1), '12');
    expect(page, '12');
  });
}
