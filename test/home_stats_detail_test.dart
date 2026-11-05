// Home stat detail screens (Worker A): lesson-key parsing,
// chapters grouping, lessonsTodayList day-rollover, and the three
// stat cards' navigation targets. No DB, no Edge, no invented
// rows: malformed keys are skipped, stale days yield empty lists.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/features/home/opened_chapters_screen.dart';
import 'package:yes_sir_ai/features/home/today_lessons_screen.dart';
import 'package:yes_sir_ai/features/home/widgets/home_stats_row.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

String _todayStr() {
  final n = DateTime.now();
  return '${n.year}-${n.month}-${n.day}';
}

GoRouter _router(String start) => GoRouter(initialLocation: start, routes: [
      GoRoute(
        path: '/home',
        builder: (c, s) => const Scaffold(
          body: HomeStatsRow(
            todayLabel: 'TODAY-LBL',
            chaptersLabel: 'CHAPTERS-LBL',
            savedLabel: 'SAVED-LBL',
            values: [2, 3, 4],
            bangla: false,
          ),
        ),
      ),
      GoRoute(
        path: '/home/today-lessons',
        builder: (c, s) => const TodayLessonsScreen(),
      ),
      GoRoute(
        path: '/home/opened-chapters',
        builder: (c, s) => const OpenedChaptersScreen(),
      ),
      GoRoute(
        path: '/home/subjects/:subjectId/chapters',
        builder: (c, s) => Scaffold(
          body: Text('CHAPTERS ${s.pathParameters['subjectId']}'),
        ),
      ),
      GoRoute(path: '/saved',
          builder: (c, s) => const Scaffold(body: Text('SAVED'))),
      GoRoute(path: '/search',
          builder: (c, s) => const Scaffold(body: Text('SEARCH'))),
      GoRoute(path: '/lesson',
          builder: (c, s) => const Scaffold(body: Text('LESSON'))),
    ]);

void main() {
  group('parseTodayLessonKey', () {
    test('valid key parses all four parts', () {
      final lesson = parseTodayLessonKey('math|3|45|5')!;
      expect(lesson.subject, 'math');
      expect(lesson.chapter, 3);
      expect(lesson.page, 45);
      expect(lesson.problem, 5);
    });

    test('malformed keys are null, never guessed values', () {
      expect(parseTodayLessonKey('math|3|45'), isNull); // too few
      expect(parseTodayLessonKey('math|3|45|5|x'), isNull); // too many
      expect(parseTodayLessonKey('math|x|45|5'), isNull); // non-numeric
      expect(parseTodayLessonKey('math|3|45|'), isNull); // empty problem
      expect(parseTodayLessonKey('|3|45|5'), isNull); // empty subject
      expect(parseTodayLessonKey('math|0|45|5'), isNull); // zero chapter
      expect(parseTodayLessonKey('math|3|45|-1'), isNull); // negative
      expect(parseTodayLessonKey('not-a-key'), isNull);
      expect(parseTodayLessonKey(''), isNull);
    });
  });

  group('groupOpenedChapters', () {
    test('first-seen subject order, numeric chapters, dedupe', () {
      final groups = groupOpenedChapters([
        'science|10',
        'math|3',
        'science|2',
        'math|3', // duplicate key: kept once
        'math|1',
      ]);
      expect(groups.map((g) => g.subject), ['science', 'math']);
      expect(groups[0].chapters, [2, 10]);
      expect(groups[1].chapters, [1, 3]);
    });

    test('malformed chapter keys are skipped', () {
      final groups = groupOpenedChapters([
        'math|3',
        'math|x',
        'math|0',
        '|2',
        'science',
        'science|2|extra',
      ]);
      expect(groups.length, 1);
      expect(groups.single.subject, 'math');
      expect(groups.single.chapters, [3]);
    });

    test('empty input yields no groups', () {
      expect(groupOpenedChapters([]), isEmpty);
    });
  });

  group('LearnStore.lessonsTodayList', () {
    test('returns today ids only', () async {
      SharedPreferences.setMockInitialValues({
        'area2_today': _todayStr(),
        'area2_lessons_today_ids': ['math|3|45|5', 'science|2|10|1'],
      });
      expect(await LearnStore.lessonsTodayList(),
          ['math|3|45|5', 'science|2|10|1']);
    });

    test('stale day yields empty, never yesterday lessons', () async {
      SharedPreferences.setMockInitialValues({
        'area2_today': '2000-1-1',
        'area2_lessons_today_ids': ['math|3|45|5'],
      });
      expect(await LearnStore.lessonsTodayList(), isEmpty);
      // summary() counting semantics unchanged alongside it.
      expect((await LearnStore.summary()).lessonsToday, 0);
    });

    test('no stored day yields empty', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await LearnStore.lessonsTodayList(), isEmpty);
    });
  });

  group('HomeStatsRow navigation', () {
    testWidgets('today card -> /home/today-lessons', (t) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(MaterialApp.router(routerConfig: _router('/home')));
      await t.tap(find.text('TODAY-LBL'));
      await t.pumpAndSettle();
      expect(find.text('আজকের লেসন'), findsOneWidget);
    });

    testWidgets('chapters card -> /home/opened-chapters', (t) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(MaterialApp.router(routerConfig: _router('/home')));
      await t.tap(find.text('CHAPTERS-LBL'));
      await t.pumpAndSettle();
      expect(find.text('খোলা অধ্যায়'), findsOneWidget);
    });

    testWidgets('saved card -> /saved (existing route)', (t) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(MaterialApp.router(routerConfig: _router('/home')));
      await t.tap(find.text('SAVED-LBL'));
      await t.pumpAndSettle();
      expect(find.text('SAVED'), findsOneWidget);
    });
  });

  group('detail screens', () {
    testWidgets('today screen: empty state is honest, no rows',
        (t) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(
          MaterialApp.router(routerConfig: _router('/home/today-lessons')));
      await t.pumpAndSettle();
      expect(find.text('আজ এখনো কোনো লেসন খোলা হয়নি'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('today row tap sets selection + goes /lesson',
        (t) async {
      SharedPreferences.setMockInitialValues({
        'area2_today': _todayStr(),
        'area2_lessons_today_ids': ['math|3|45|5', 'bad-key'],
      });
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(
          MaterialApp.router(routerConfig: _router('/home/today-lessons')));
      await t.pumpAndSettle();
      // The malformed 'bad-key' is skipped: exactly one row.
      expect(find.byType(ListTile), findsOneWidget);
      await t.tap(find.text('গণিত · অধ্যায় ৩ · পৃষ্ঠা ৪৫ · প্রশ্ন ৫'));
      await t.pumpAndSettle();
      expect(find.text('LESSON'), findsOneWidget);
      expect(LessonSelectionHolder.current.subject, 'math');
      expect(LessonSelectionHolder.current.page, 45);
      expect(LessonSelectionHolder.current.problem, 5);
    });

    testWidgets('opened chapters: empty state is honest', (t) async {
      SharedPreferences.setMockInitialValues({});
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(MaterialApp.router(
          routerConfig: _router('/home/opened-chapters')));
      await t.pumpAndSettle();
      expect(find.text('এখনো কোনো অধ্যায় খোলা হয়নি'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('opened chapters: empty state + row goes to chapters',
        (t) async {
      SharedPreferences.setMockInitialValues({
        'area2_chapters': ['science|2'],
      });
      languageNotifier.value = const Locale('bn');
      await t.pumpWidget(MaterialApp.router(
          routerConfig: _router('/home/opened-chapters')));
      await t.pumpAndSettle();
      expect(find.text('বিজ্ঞান'), findsOneWidget);
      await t.tap(find.text('অধ্যায় ২'));
      await t.pumpAndSettle();
      expect(find.text('CHAPTERS science'), findsOneWidget);
    });
  });
}
