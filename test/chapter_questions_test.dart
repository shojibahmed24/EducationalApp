// Worker A tests: textbook chapter list (second step).
// Fixture mirrors the VERIFIED class 6 maths ch.3 counts only
// (total 25, MCQ 5, short 3, creative 1, other-incl-untyped 16);
// stems are short dummies, never real question text. The Edge
// is always a fake [post], never a live call.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/services/textbook_chapter_service.dart';
import 'package:yes_sir_ai/features/learn/chapter_questions_screen.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/features/learn/widgets/digits.dart';
import 'package:yes_sir_ai/features/learn/widgets/textbook_filter.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
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

/// 25 rows: 5 mcq, 3 short, 1 creative, 16 other (10 null type +
/// 6 unknown 'essay' type, proving anything-else -> other).
List<TextbookChapterQuestion> fixture() => [
      r('mcq1', 'বাগান MCQ stem', 10, 1, 'mcq'),
      r('mcq2', 'MCQ stem 2', 10, 2, 'mcq'),
      r('mcq3', 'MCQ stem 3', 11, 1, 'mcq'),
      r('mcq4', 'MCQ stem 4', 12, null, 'mcq'),
      r('mcq5', 'MCQ stem 5', 12, 3, 'mcq'),
      r('short1', 'Short stem 1', 13, 1, 'short'),
      r('short2', 'Short stem 2', 13, 2, 'short'),
      r('short3', 'Short stem 3', 14, 1, 'short'),
      r('cre1', 'Creative stem', 15, 1, 'creative'),
      r('o1', 'বাগান other stem', 16, null, null),
      r('o2', 'Other stem 2', 16, 1, null),
      r('o3', 'Other stem 3', 17, 2, null),
      r('o4', 'Other stem 4', 17, null, null),
      r('o5', 'Other stem 5', 18, 1, null),
      r('o6', 'Other stem 6', 18, 2, null),
      r('o7', 'Other stem 7', 19, 1, null),
      r('o8', 'Other stem 8', 19, null, null),
      r('o9', 'Other stem 9', 20, 1, null),
      r('o10', 'Other stem 10', 20, 2, null),
      r('o11', 'Other stem 11', 21, 1, 'essay'),
      r('o12', 'Other stem 12', 21, 2, 'essay'),
      r('o13', 'Other stem 13', 22, 1, 'essay'),
      r('o14', 'Other stem 14', 22, null, 'essay'),
      r('o15', 'Other stem 15', 23, 1, 'essay'),
      r('o16', 'Other stem 16', 23, 2, 'essay'),
    ];

/// Drags the chapter ListView until [f] is built (ListView builds
/// lazily, so off-screen widgets are not in the tree at all).
/// scrollUntilVisible cannot be used here: its default scrollable
/// finder is ambiguous because each TextField owns a Scrollable.
Future<void> scrollTo(WidgetTester tester, Finder f, {bool up = false}) async {
  for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
    await tester.drag(
        find.byType(ListView), Offset(0, up ? 1500 : -1500));
    await tester.pumpAndSettle();
  }
}

Map<String, dynamic> fakeListPayload(List<TextbookChapterQuestion> rows) =>
    {
      'found': true,
      'bookTitle': 'Fake book',
      'chapterTitle': 'Fake chapter',
      'chapterNumber': 3,
      'questions': rows
          .map((q) => {
                'id': q.id,
                'questionText': q.questionText,
                'page': q.page,
                'problem': q.problem,
                'questionType': q.questionType,
                // Junk the model must ignore: never rendered.
                'answer': 'FAKE ANSWER MUST NOT APPEAR',
                'solution': 'FAKE SOLUTION MUST NOT APPEAR',
                'chunks': ['FAKE CHUNK'],
              })
          .toList(),
    };

void main() {
  group('verified ch.3 counts', () {
    test('total 25 with MCQ 5, short 3, creative 1, other 16', () {
      final all = fixture();
      expect(all.length, 25);
      final present = {
        for (final e in textbookPresentTypes(all)) e.$1: e.$2
      };
      expect(present, {'mcq': 5, 'short': 3, 'creative': 1, 'other': 16});
    });

    test('null-problem row keeps its id and shows page only', () {
      final all = fixture();
      final filtered = filterTextbookQuestions(
          all: all, type: 'all', query: '', page: null);
      final nullProblem =
          filtered.where((q) => q.problem == null).toList();
      expect(nullProblem.map((q) => q.id),
          containsAll(['mcq4', 'o1', 'o4', 'o8', 'o14']));
      expect(
        textbookRowMeta(
            r('o1', 'x', 16, null, null), chapterQuestionsStringsBn, true),
        'পৃষ্ঠা ${numStr(16, true)}',
      );
      expect(
        textbookRowMeta(
            r('mcq1', 'x', 10, 1, 'mcq'), chapterQuestionsStringsBn, true),
        'পৃষ্ঠা ${numStr(10, true)} · প্রশ্ন ${numStr(1, true)}',
      );
    });
  });

  group('list payload model', () {
    test('fromJson parses contract fields, ignores answer/chunks', () {
      final q = TextbookChapterQuestion.fromJson({
        'id': 'q9',
        'questionText': 'stem',
        'page': 45,
        'problem': 5,
        'questionType': 'mcq',
        'answer': 'MUST BE IGNORED',
        'solution': 'MUST BE IGNORED',
        'chunks': ['MUST BE IGNORED'],
        'answerKey': 'MUST BE IGNORED',
      });
      expect(q.id, 'q9');
      expect(q.questionText, 'stem');
      expect(q.page, 45);
      expect(q.problem, 5);
      expect(q.questionType, 'mcq');
      // The model exposes no answer/solution/chunk field at all:
      // there is nothing to assert them on (compile-time fact).
    });

    test('sorting: page asc, problem asc, null problems last', () {
      final sorted = sortChapterQuestions([
        r('a', 'x', 12, null, null),
        r('b', 'x', 10, 2, null),
        r('c', 'x', 10, 1, null),
        r('d', 'x', 10, null, null),
      ]);
      expect(sorted.map((q) => q.id).toList(), ['c', 'b', 'd', 'a']);
    });
  });

  group('service with fake Edge', () {
    test('fetchChapter sorts, null = unavailable, [] = found-empty', () async {
      final svc = TextbookChapterService(
          post: (_) async => fakeListPayload([
                r('b', 'x', 12, 1, 'short'),
                r('a', 'x', 10, 1, 'short'),
              ]));
      final rows = await svc.fetchChapter('math', 6, 3, true);
      expect(rows!.map((q) => q.id).toList(), ['a', 'b']);
      final unavailable =
          TextbookChapterService(post: (_) async => null);
      expect(await unavailable.fetchChapter('math', 6, 3, true), isNull);
      final empty = TextbookChapterService(
          post: (_) async => {'found': true, 'questions': []});
      expect(await empty.fetchChapter('math', 6, 3, true), isEmpty);
      final notFound = TextbookChapterService(
          post: (_) async => {'found': false});
      expect(await notFound.fetchChapter('math', 6, 3, true), isNull);
    });

    test('resolveById builds Mode-A grounding, max 3 chunks', () async {
      final svc = TextbookChapterService(post: (_) async => {
            'found': true,
            'bookTitle': 'B',
            'chapterTitle': 'C',
            'chapterNumber': 3,
            'page': 45,
            'problem': 5,
            'questionText': 'by-id stem',
            'chunks': [
              {'text': 'c1', 'pageStart': 44, 'pageEnd': 45},
              {'text': 'c2', 'pageStart': 45, 'pageEnd': 46},
              {'text': 'c3', 'pageStart': 46, 'pageEnd': 47},
              {'text': 'c4-DROPPED', 'pageStart': 47, 'pageEnd': 48},
            ],
          });
      final g = await svc.resolveById('q-id', true, subject: 'math');
      expect(g.found, isTrue);
      expect(g.context!.questionText, 'by-id stem');
      expect(g.context!.page, 45);
      expect(g.context!.problem, 5);
      expect(g.context!.chunkTexts, ['c1', 'c2', 'c3']);
      final missing =
          TextbookChapterService(post: (_) async => {'found': false});
      expect((await missing.resolveById('x', true)).found, isFalse);
    });
  });

  group('search shortcut decision (no live Edge)', () {
    test('exact found -> lesson', () {
      expect(
          decideSearchShortcut(exactFound: true, chapterExists: true),
          SearchShortcut.lesson);
    });
    test('miss + chapter exists -> chapter list, never no-match', () {
      expect(
          decideSearchShortcut(exactFound: false, chapterExists: true),
          SearchShortcut.chapterList);
    });
    test('miss + chapter missing -> no-match', () {
      expect(
          decideSearchShortcut(exactFound: false, chapterExists: false),
          SearchShortcut.noMatch);
    });
  });

  group('chapter screen widget (fake Edge)', () {
    testWidgets('20-increment, filter reset-to-20, empty-filter clear',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      final svc = TextbookChapterService(
          post: (_) async => fakeListPayload(fixture()));
      await tester.pumpWidget(MaterialApp(
        home: ChapterQuestionsScreen(
          subjectId: 'math',
          chapterNumber: 3,
          schoolClass: 6,
          service: svc,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('এই অধ্যায়ে মোট ২৫টি প্রশ্ন'), findsOneWidget);
      expect(find.text('মোট ২৫টির মধ্যে ২০টি দেখাচ্ছে'), findsOneWidget);
      expect(find.text('FAKE ANSWER MUST NOT APPEAR'), findsNothing);
      expect(find.text('FAKE SOLUTION MUST NOT APPEAR'), findsNothing);
      // +20 per tap covers all 25.
      await scrollTo(tester, find.text('আরো দেখুন'));
      await tester.tap(find.text('আরো দেখুন'));
      await tester.pumpAndSettle();
      // Showing text lives near the top: scroll back before
      // asserting it, or the lazy ListView has unbuilt it.
      await scrollTo(tester, find.text('মোট ২৫টির মধ্যে ২৫টি দেখাচ্ছে'),
          up: true);
      expect(find.text('মোট ২৫টির মধ্যে ২৫টি দেখাচ্ছে'), findsOneWidget);
      // Filter change resets visible to 20: mcq (5) then all (20).
      await scrollTo(tester, find.text('বহুনির্বাচনি (5)'), up: true);
      await tester.tap(find.text('বহুনির্বাচনি (5)'));
      await tester.pumpAndSettle();
      expect(find.text('মোট ৫টির মধ্যে ৫টি দেখাচ্ছে'), findsOneWidget);
      await scrollTo(tester, find.text('সব ধরন'), up: true);
      await tester.tap(find.text('সব ধরন'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('মোট ২৫টির মধ্যে ২০টি দেখাচ্ছে'),
          up: true);
      expect(find.text('মোট ২৫টির মধ্যে ২০টি দেখাচ্ছে'), findsOneWidget);
      // Empty filtered result + clear button resets all filters.
      await scrollTo(tester, find.byType(TextField).first, up: true);
      await tester.enterText(
          find.byType(TextField).first, 'zzzz-no-match');
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('এই ছাঁকনিতে কিছু মেলেনি'));
      expect(find.text('এই ছাঁকনিতে কিছু মেলেনি'), findsOneWidget);
      expect(find.text('ছাঁকনি মুছুন'), findsOneWidget);
      await scrollTo(tester, find.text('ছাঁকনি মুছুন'));
      await tester.tap(find.text('ছাঁকনি মুছুন'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('মোট ২৫টির মধ্যে ২০টি দেখাচ্ছে'),
          up: true);
      expect(find.text('মোট ২৫টির মধ্যে ২০টি দেখাচ্ছে'), findsOneWidget);
    });
  });
}
