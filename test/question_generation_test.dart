// Batch 2 (items 8/9): selector + generation + weak revision tests.
// Pure selector tests need no prefs; weak tests use mocked prefs.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/model_test_service.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/core/services/question_generation.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';

QuizItem _item(String id) => QuizItem(
    id: id, questionBn: id, questionEn: id,
    options: const ['a', 'b', 'c', 'd'], correctIndex: 0);

List<QuizItem> _pool() => [
      _item('a1'), _item('a2'), _item('b1'), _item('b2'),
      _item('c1'), _item('c2'),
    ];

void main() {
  test('selector is deterministic for the same seed', () {
    final one = questionGeneration.selectQuestions(
        pool: _pool(), count: 4, seedKey: 'daily-6-math-2026-10-28',
        chapterOf: (q) => q.id[0]);
    final two = questionGeneration.selectQuestions(
        pool: _pool(), count: 4, seedKey: 'daily-6-math-2026-10-28',
        chapterOf: (q) => q.id[0]);
    expect(one.map((q) => q.id).toList(),
        two.map((q) => q.id).toList());
  });

  test('selector covers every chapter before repeating one', () {
    final set = questionGeneration.selectQuestions(
        pool: _pool(), count: 4, seedKey: 'seed-x',
        chapterOf: (q) => q.id[0]);
    expect(set.length, 4);
    expect(set.map((q) => q.id).toSet().length, 4); // no repeats
    expect(set.map((q) => q.id[0]).toSet(), {'a', 'b', 'c'});
  });

  test('selector caps at the pool size and dedupes ids', () {
    final pool = [..._pool(), _item('a1')]; // duplicate id
    final set = questionGeneration.selectQuestions(
        pool: pool, count: 99, seedKey: 'seed-y',
        chapterOf: (q) => q.id[0]);
    expect(set.length, 6);
    expect(set.map((q) => q.id).toSet().length, 6);
  });

  test('daily quiz is 5, same day same set', () {
    final one = practiceService.dailyQuizFor('math', seedKey: 'd1');
    final two = practiceService.dailyQuizFor('math', seedKey: 'd1');
    expect(one.length, 5);
    expect(one.map((q) => q.id).toList(),
        two.map((q) => q.id).toList());
  });

  test('model tests keep fixed counts and english stays locked', () {
    final tests = modelTestService.modelTests();
    expect(tests.firstWhere((t) => t.id == 'mt-math').items.length, 10);
    expect(tests.firstWhere((t) => t.id == 'mt-science').items.length, 8);
    final en = tests.firstWhere((t) => t.id == 'mt-english');
    expect(en.locked, isTrue);
    expect(en.items, isEmpty);
  });

  test('generateDailyQuiz with no guide returns an empty guide set',
      () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await practiceService.generateDailyQuiz(
        subject: 'math', schoolClass: 6, bangla: true);
    // No server in tests -> guide empty -> the SCREEN asks
    // about a bank set; the service never substitutes silently.
    expect(gen.items, isEmpty);
    expect(gen.source, QuestionSource.guide);
    expect(gen.guideShortfall, 20);
    expect(gen.bookQuestionsIndexed, 0); // no server in tests
  });

  test('weak revision is newest-first wrong answers, deduped', () async {
    SharedPreferences.setMockInitialValues({});
    PracticeSession.lastAttempt = null;
    await PracticeStore.saveAttempt(Attempt(kind: 'quiz',
        testId: 'quiz-math', subject: 'math', chapter: 'math',
        correct: 1, total: 2, seconds: 60, date: '2026-10-27',
        answers: {'mq1': 0, 'mq2': 2})); // mq1 wrong, mq2 right
    await PracticeStore.saveAttempt(Attempt(kind: 'quiz',
        testId: 'quiz-math', subject: 'math', chapter: 'math',
        correct: 0, total: 2, seconds: 60, date: '2026-10-28',
        answers: {'mq3': 0, 'mq1': 0})); // mq3 + mq1 wrong again
    final weak = await practiceService.weakRevisionItems();
    expect(weak.map((q) => q.id).toList(), ['mq3', 'mq1']);
    final sum = await progressService.summary();
    expect(sum.weakItems.map((q) => q.id).toList(), ['mq3', 'mq1']);
  });

  test('weak revision is empty with no wrong answers', () async {
    SharedPreferences.setMockInitialValues({});
    PracticeSession.lastAttempt = null;
    await PracticeStore.saveAttempt(Attempt(kind: 'quiz',
        testId: 'quiz-math', subject: 'math', chapter: 'math',
        correct: 1, total: 1, seconds: 30, date: '2026-10-28',
        answers: {'mq2': 2})); // correct only
    expect(await practiceService.weakRevisionItems(), isEmpty);
  });
}
