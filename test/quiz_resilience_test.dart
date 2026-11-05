// Quiz resilience (Phase 2, plan §2 step 2 — the silent bank
// fallback is GONE): a failing book probe or guide fetch must
// NEVER abort the quiz future, but it must also NEVER silently
// substitute the bank. The service returns an empty guide set
// with shortfall 20 (the screen asks the user about a bank
// set); a short guide set ships verbatim with its shortfall.
// Guide throw/hang are injected through the PracticeService
// seam methods, so guide_quiz_service.dart itself is untouched.
// NOTE on busy flags: the screens' private _startingDaily /
// _startingSubject flags cannot be driven to a throw from a widget
// test (the real guide singleton + profile read do not throw in
// the test harness), so the widget-level throw case is covered by
// (a) these service tests proving the futures COMPLETE (never
// hang/throw) on every failure, and (b) a code-level finally audit
// of all three _start* methods (flag cleared iff not navigated).
// The progress string itself is asserted present in both locales.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/question_generation.dart';
import 'package:yes_sir_ai/features/practice/practice_screen.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/practice_strings.dart';

QuizItem _guide(String id) => QuizItem(
    id: id, questionBn: id, questionEn: id,
    options: const ['a', 'b', 'c', 'd'], correctIndex: 0);

List<QuizItem> _guideSet(int n) =>
    [for (var i = 0; i < n; i++) _guide('g$i')];

class _ProbeThrowingService extends PracticeService {
  @override
  Future<List<BookQuestion>?> fetchBookProbe(
      {required String subject,
      required int schoolClass,
      required bool bangla}) async =>
      throw StateError('probe boom');
}

class _GuideThrowingService extends PracticeService {
  @override
  Future<List<QuizItem>> fetchGuideDaily(
      {required String subject,
      required int schoolClass,
      required bool bangla,
      required String day}) async =>
      throw StateError('guide boom');

  @override
  Future<List<QuizItem>> fetchPracticeGuide(
      {required String subject,
      required int schoolClass,
      required bool bangla}) async =>
      throw StateError('guide boom');
}

class _GuideHangingService extends PracticeService {
  @override
  Future<List<QuizItem>> fetchGuideDaily(
      {required String subject,
      required int schoolClass,
      required bool bangla,
      required String day}) =>
      Completer<List<QuizItem>>().future;

  @override
  Future<List<QuizItem>> fetchPracticeGuide(
      {required String subject,
      required int schoolClass,
      required bool bangla}) =>
      Completer<List<QuizItem>>().future;
}

class _GuidePartialService extends PracticeService {
  @override
  Future<List<QuizItem>> fetchGuideDaily(
      {required String subject,
      required int schoolClass,
      required bool bangla,
      required String day}) async =>
      _guideSet(2); // < 5: must fall back, never a 2-item quiz
}

class _GuideFullService extends PracticeService {
  @override
  Future<List<QuizItem>> fetchGuideDaily(
      {required String subject,
      required int schoolClass,
      required bool bangla,
      required String day}) async =>
      _guideSet(5);
}

void main() {
  test('book-probe throw still completes: empty guide set, ask', () async {
    final gen = await _ProbeThrowingService().generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
    expect(gen.bookQuestionsIndexed, 0);
  });

  test('guide throw yields an empty guide set, never silent bank',
      () async {
    final gen = await _GuideThrowingService().generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
  });

  test('guide hang yields an empty guide set via the timeout',
      () async {
    final gen = await _GuideHangingService().generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true,
        guideTimeout: const Duration(milliseconds: 100));
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
  });

  test('guide 2 items ships verbatim with shortfall 18', () async {
    final gen = await _GuidePartialService().generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    expect(gen.items.map((q) => q.id).toList(), ['g0', 'g1']);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 18);
  });

  test('guide 5 items still wins, verbatim, scoring untouched',
      () async {
    final gen = await _GuideFullService().generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    expect(gen.source, QuestionSource.guide);
    expect(gen.items.map((q) => q.id).toList(),
        ['g0', 'g1', 'g2', 'g3', 'g4']);
    expect(gen.guideShortfall, 15);
    expect(gen.items.every((q) => q.correctIndex == 0), isTrue);
    expect(gen.items.every((q) => q.options.length == 4), isTrue);
  });

  test('subject practice: guide throw yields an empty guide set',
      () async {
    final gen = await _GuideThrowingService().generatePracticeQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
    expect(gen.bookQuestionsIndexed, 0);
  });

  test('subject practice: guide hang yields an empty guide set',
      () async {
    final gen = await _GuideHangingService().generatePracticeQuiz(
        subject: 'math', schoolClass: 6, bangla: true,
        guideTimeout: const Duration(milliseconds: 100));
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
  });

  test('progress string exists in both locales', () {
    expect(practiceStringsBn['preparingGuide'], isNotEmpty);
    expect(practiceStringsEn['preparingGuide'], isNotEmpty);
  });

  testWidgets(
      'edited daily button asks before a bank set, then lands on a 5-item quiz',
      (WidgetTester t) async {
    SharedPreferences.setMockInitialValues({});
    PracticeSession.selectedSubject = 'math';
    PracticeSession.quizItems = [];
    PracticeSession.quizIsRevision = false;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.lastAttempt = null;
    PracticeSession.lastItems = [];
    languageNotifier.value = const Locale('bn');
    final router = GoRouter(initialLocation: '/practice', routes: [
      GoRoute(path: '/practice',
          builder: (c, s) => const PracticeScreen()),
      GoRoute(path: '/home',
          builder: (c, s) => const Scaffold(body: Text('HOME'))),
      GoRoute(path: '/guide-model-tests',
          builder: (c, s) => const Scaffold(body: Text('MODELS'))),
      GoRoute(path: '/practice-tab',
          builder: (c, s) => const Scaffold(body: Text('TAB'))),
      GoRoute(path: '/quiz',
          builder: (c, s) => Scaffold(body: Center(child: Text(
              'QUIZ ${PracticeSession.quizItems.length} items')))),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    await t.tap(find.text('কুইজ শুরু করো'));
    await t.pumpAndSettle();
    // No server in tests -> guide empty -> the dialog asks
    // before any bank set starts (never silent substitution).
    expect(find.text('ব্যাংক-সেট দিয়ে শুরু করো'), findsOneWidget);
    await t.tap(find.text('ব্যাংক-সেট দিয়ে শুরু করো'));
    await t.pumpAndSettle();
    expect(find.textContaining('QUIZ 5 items'), findsOneWidget);
  });
}
