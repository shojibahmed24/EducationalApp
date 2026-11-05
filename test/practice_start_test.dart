// Batch 2 (item 8): the practice + practice-tab start buttons
// really start a quiz with the right questions — daily = the
// 20-question guide set (the 5-item bank pool yields 5), weak
// revision = exactly the wrong answers, and the weak button is
// disabled when there are truly no wrongs. Phase 2: an empty
// guide set asks about a bank set first (dialog), never
// silently substituting the bank.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/features/practice/practice_screen.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/practice_tab_screen.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

Widget _quizStub() => Scaffold(body: Center(child: Text(
    'QUIZ ${PracticeSession.quizItems.length} items '
    '${PracticeSession.quizIsRevision ? 'revision' : 'daily'} '
    '${PracticeSession.quizItems.map((q) => q.id).join(',')}')));

GoRouter _router(String start) => GoRouter(initialLocation: start, routes: [
      GoRoute(path: '/practice',
          builder: (c, s) => const PracticeScreen()),
      GoRoute(path: '/practice-tab',
          builder: (c, s) => const PracticeTabScreen()),
      GoRoute(path: '/quiz', builder: (c, s) => _quizStub()),
      GoRoute(path: '/model-test-exam',
          builder: (c, s) => const Scaffold(body: Text('EXAM'))),
      GoRoute(path: '/model-tests',
          builder: (c, s) => const Scaffold(body: Text('LIST'))),
      GoRoute(path: '/quiz-results',
          builder: (c, s) => const Scaffold(body: Text('RESULTS'))),
      GoRoute(path: '/progress',
          builder: (c, s) => const Scaffold(body: Text('PROGRESS'))),
      GoRoute(path: '/home',
          builder: (c, s) => const Scaffold(body: Text('HOME'))),
    ]);

Future<void> _reset() async {
  SharedPreferences.setMockInitialValues({});
  PracticeSession.selectedSubject = 'math';
  PracticeSession.quizItems = [];
  PracticeSession.quizIsRevision = false;
  PracticeSession.quizSource = 'bankFallback';
  PracticeSession.lastAttempt = null;
  PracticeSession.lastItems = [];
  languageNotifier.value = const Locale('bn');
}

Future<void> _seedWrong() async {
  await PracticeStore.saveAttempt(Attempt(kind: 'quiz',
      testId: 'quiz-math', subject: 'math', chapter: 'math',
      correct: 1, total: 2, seconds: 60, date: '2026-10-28',
      answers: {'mq1': 0, 'mq2': 2})); // mq1 wrong, mq2 right
}

void main() {
  testWidgets('practice daily button asks, then starts a bank quiz',
      (WidgetTester t) async {
    await _reset();
    await t.pumpWidget(MaterialApp.router(routerConfig: _router('/practice')));
    await t.pumpAndSettle();
    await t.tap(find.text('কুইজ শুরু করো'));
    await t.pumpAndSettle();
    // No server in tests -> guide empty -> dialog first.
    expect(find.text('ব্যাংক-সেট দিয়ে শুরু করো'), findsOneWidget);
    await t.tap(find.text('ব্যাংক-সেট দিয়ে শুরু করো'));
    await t.pumpAndSettle();
    expect(find.textContaining('QUIZ 5 items daily'), findsOneWidget);
  });

  testWidgets('practice weak button starts revision with wrong items only',
      (WidgetTester t) async {
    await _reset();
    await _seedWrong();
    await t.pumpWidget(MaterialApp.router(routerConfig: _router('/practice')));
    await t.pumpAndSettle();
    expect(find.textContaining('1টি ভুল প্রশ্ন'), findsOneWidget);
    await t.tap(find.text('রিভিশন শুরু করো'));
    await t.pumpAndSettle();
    expect(find.textContaining('QUIZ 1 items revision mq1'),
        findsOneWidget);
  });

  testWidgets('practice weak button is disabled with no wrong answers',
      (WidgetTester t) async {
    await _reset();
    await t.pumpWidget(MaterialApp.router(routerConfig: _router('/practice')));
    await t.pumpAndSettle();
    expect(find.text('এখনো কোনো ভুল নেই — কুইজ দিয়ে শুরু করো'),
        findsOneWidget);
    final btn = t.widget<TextButton>(
        find.widgetWithText(TextButton, 'রিভিশন শুরু করো'));
    expect(btn.onPressed, isNull);
  });

  testWidgets('practice-tab weak button starts revision with wrong items',
      (WidgetTester t) async {
    await _reset();
    await _seedWrong();
    await t.pumpWidget(
        MaterialApp.router(routerConfig: _router('/practice-tab')));
    await t.pumpAndSettle();
    await t.tap(find.text('রিভিশন শুরু করো'));
    await t.pumpAndSettle();
    expect(find.textContaining('QUIZ 1 items revision mq1'),
        findsOneWidget);
  });

  testWidgets('practice-tab daily button asks, then starts a bank quiz',
      (WidgetTester t) async {
    await _reset();
    await t.pumpWidget(
        MaterialApp.router(routerConfig: _router('/practice-tab')));
    await t.pumpAndSettle();
    expect(find.textContaining('গাইড MCQ'), findsOneWidget);
    await t.tap(find.text('শুরু করো').first);
    await t.pumpAndSettle();
    // No server in tests -> guide empty -> dialog first.
    expect(find.text('ব্যাংক-সেট দিয়ে শুরু করো'), findsOneWidget);
    await t.tap(find.text('ব্যাংক-সেট দিয়ে শুরু করো'));
    await t.pumpAndSettle();
    expect(find.textContaining('QUIZ 5 items daily'), findsOneWidget);
  });
}
