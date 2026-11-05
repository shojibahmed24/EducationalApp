// Fix-round items 2, 3, 4, 8 (code + tests only):
//  1. SolutionRichText default colour is theme-aware (onSurface).
//  2. settings_strings 'student' is the generic fallback, matching
//     profile_strings — no personal name in lib/l10n/.
//  3. By-id resolve forwards the known class into the returned
//     context (resolveById's schoolClass param); the by-id Edge
//     payload itself carries no classId (contract unchanged).
//  4. Weak-chapter labels for guide ids parse to a real
//     অধ্যায় N / Chapter N label (same -ch<N>- pattern the
//     guide-quiz chapter label uses); unparseable ids get no
//     label, never a wrong or generic one.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/core/services/textbook_chapter_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_rich_text.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/l10n/pages/profile_strings.dart';
import 'package:yes_sir_ai/l10n/pages/settings_strings.dart';

Color? _rootColor(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).first);
  return (rich.text as TextSpan).style?.color;
}

void main() {
  group('SolutionRichText theme-aware default colour', () {
    testWidgets('no colour -> light onSurface', (tester) async {
      const onSurface = Color(0xFF112233);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
              colorScheme: const ColorScheme.light(onSurface: onSurface)),
          home: const Scaffold(
            body: SolutionRichText(text: 'plain text', fontSize: 16),
          ),
        ),
      );
      expect(_rootColor(tester), onSurface);
    });

    testWidgets('no colour -> dark onSurface, never forced light ink',
        (tester) async {
      const onSurface = Color(0xFFEEFF00);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
              colorScheme: const ColorScheme.dark(onSurface: onSurface)),
          home: const Scaffold(
            body: SolutionRichText(
                text: r'math $x^2$ and **bold**', fontSize: 16),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_rootColor(tester), onSurface);
    });

    testWidgets('explicit colour is preserved in both themes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
              colorScheme:
                  const ColorScheme.dark(onSurface: Color(0xFFEEFF00))),
          home: const Scaffold(
            body: SolutionRichText(
                text: 'explicit', fontSize: 16, color: Colors.red),
          ),
        ),
      );
      expect(_rootColor(tester), Colors.red);
    });
  });

  group('settings generic student fallback', () {
    test('matches profile_strings generic fallback, no personal name',
        () {
      expect(settingsStringsBn['student'], 'শিক্ষার্থী');
      expect(settingsStringsEn['student'], 'Student');
      expect(settingsStringsBn['student'], profileStringsBn['student']);
      expect(settingsStringsEn['student'], profileStringsEn['student']);
      for (final v in [settingsStringsBn['student']!,
          settingsStringsEn['student']!]) {
        expect(v, isNot(contains('Sadman')));
        expect(v, isNot(contains('সাদমান')));
        expect(v, isNot(contains('Rafi')));
        expect(v, isNot(contains('Sakib')));
      }
    });
  });

  group('by-id context carries the passed class', () {
    Map<String, dynamic> fakePayload() => {
          'found': true,
          'bookTitle': 'B',
          'chapterTitle': 'C',
          'chapterNumber': 3,
          'page': 45,
          'problem': 5,
          'questionText': 'by-id stem',
          'chunks': [],
        };

    test('schoolClass 7 is threaded into the context', () async {
      final svc = TextbookChapterService(post: (_) async => fakePayload());
      final g =
          await svc.resolveById('q-id', true, subject: 'math', schoolClass: 7);
      expect(g.found, isTrue);
      expect(g.context!.schoolClass, 7);
      expect(g.context!.subject, 'math');
    });

    test('unknown class keeps the service default (6), payload has no classId',
        () async {
      Map<String, dynamic>? seen;
      final svc = TextbookChapterService(post: (p) async {
        seen = p;
        return fakePayload();
      });
      final g = await svc.resolveById('q-id', true, subject: 'math');
      expect(g.context!.schoolClass, 6);
      expect(seen, containsPair('questionId', 'q-id'));
      expect(seen, containsPair('language', 'bn'));
      expect(seen!.containsKey('classId'), isFalse);
    });
  });

  group('weak-chapter guide-id labels', () {
    test('guide ids parse to a real chapter label, Bangla digits in Bn',
        () {
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch2-p44-ex21-mcq18', true),
          'অধ্যায় ২');
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch2-p44-ex21-mcq18', false),
          'Chapter 2');
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch10-p242-ex101smcq12', true),
          'অধ্যায় ১০');
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch10-p242-ex101smcq12', false),
          'Chapter 10');
    });

    test('unparseable ids get no label, never a wrong one', () {
      for (final id in ['zzz-unknown', '', 'class7-math-bn-guide-noch']) {
        expect(practiceService.chapterOf(id, true), '');
        expect(practiceService.chapterOf(id, false), '');
      }
    });

    test('weakChapterFor: guide id -> both labels, unparseable -> null',
        () {
      final guide = progressService.weakChapterFor(
          'class7-math-bn-guide-ch2-p44-ex21-mcq18', 3, 5)!;
      expect(guide.labelBn, 'অধ্যায় ২');
      expect(guide.labelEn, 'Chapter 2');
      expect(guide.label(true), 'অধ্যায় ২');
      expect(guide.label(false), 'Chapter 2');
      expect(guide.wrong, 3);
      expect(guide.total, 5);
      expect(progressService.weakChapterFor('zzz-unknown', 1, 1), isNull);
      expect(progressService.weakChapterFor('', 1, 1), isNull);
      // Bank ids keep their coarse bilingual labels via the same path.
      final bank = progressService.weakChapterFor('mq1', 2, 4)!;
      expect(bank.labelBn, 'গণিত · পরিমাপ ও অনুপাত');
      expect(bank.labelEn, 'Maths · Measurement & Ratio');
    });

    test('summary: no empty or generic weak label from unparseable ids',
        () async {
      SharedPreferences.setMockInitialValues({
        'ys_attempts_json': jsonEncode([
          {
            'kind': 'quiz',
            'testId': 't1',
            'subject': 'math',
            'chapter': '',
            'correct': 1,
            'total': 2,
            'seconds': 0,
            'date': PracticeSession.today(),
            // mq1 correctIndex is 2, so 0 is wrong; the unparseable
            // id can never form a weak chapter.
            'answers': {'mq1': 0, 'zzz-unknown': 0},
            'flagged': [],
          },
        ]),
      });
      final sum = await progressService.summary();
      expect(sum.weakChapters.length, 1);
      final weak = sum.weakChapters.first;
      expect(weak.labelBn, isNotEmpty);
      expect(weak.labelEn, isNotEmpty);
      expect(weak.labelBn, isNot(contains('General')));
      expect(weak.labelEn, isNot(contains('General')));
      expect(weak.labelBn, 'গণিত · পরিমাপ ও অনুপাত');
      expect(weak.labelEn, 'Maths · Measurement & Ratio');
    });
  });
}
