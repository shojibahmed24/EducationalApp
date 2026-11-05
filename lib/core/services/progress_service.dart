// Progress computed ONLY from saved attempts + activity dates.
// No static mocks: a fresh install honestly shows 0 everywhere.
// When SUPABASE_URL + SUPABASE_ANON_KEY arrive, the Supabase
// progress row is used as a fallback only if no local attempts exist.
// Phase 16 (M6): the goal unit is MINUTES, the same unit as
// Settings' daily_goal_minutes — never the old hardcoded 10
// questions/day. Today's minutes come from saved attempts: each
// Attempt records its real run time in `seconds`, so todayMinutes =
// (sum of today's attempts' seconds) ~/ 60 (whole minutes, the
// remainder is dropped, not rounded up). No profile goal saved =>
// goalMinutes = 0, and the UI shows a no-goal state, never a
// default the user never chose.
import 'dart:convert';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import '../models/backend_models.dart';
import 'local_store.dart';
import 'supabase_client.dart';
import 'practice_service.dart';

class WeakChapter {
  final String labelBn, labelEn;
  final int wrong, total;
  const WeakChapter(this.labelBn, this.labelEn, this.wrong, this.total);
  String label(bool bangla) => bangla ? labelBn : labelEn;
}

class ProgressSummary {
  final int streakDays, chaptersDone, averageScore;
  final int totalAttempts, totalCorrect, totalAnswered, xp, level;
  // todayMinutes/goalMinutes are MINUTES (see header); todayAnswered
  // is kept only as the raw question count, not the goal unit.
  final int todayAnswered, todayMinutes, goalMinutes;
  final List<String> activityDates;
  final List<WeakChapter> weakChapters;
  final List<Attempt> attempts;
  // Batch 2 (items 8/9): the actual wrong-answer questions behind
  // weakChapters, newest run first, deduped — the revision quiz
  // starts with exactly these. Empty = truly no wrong answers.
  final List<QuizItem> weakItems;
  const ProgressSummary({required this.streakDays, required this.chaptersDone,
    required this.averageScore, required this.totalAttempts,
    required this.totalCorrect, required this.totalAnswered,
    required this.xp, required this.level, required this.todayAnswered,
    required this.todayMinutes, required this.goalMinutes,
    required this.activityDates,
    required this.weakChapters, required this.attempts,
    this.weakItems = const []});
  double get goalProgress =>
      goalMinutes == 0 ? 0 : (todayMinutes / goalMinutes).clamp(0.0, 1.0);
  static const empty = ProgressSummary(streakDays: 0, chaptersDone: 0,
      averageScore: 0, totalAttempts: 0, totalCorrect: 0, totalAnswered: 0,
      xp: 0, level: 1, todayAnswered: 0, todayMinutes: 0, goalMinutes: 0,
      activityDates: [], weakChapters: [], attempts: []);
}

class ProgressService {
  /// The user's own goal in minutes (Settings daily_goal_minutes).
  /// 0 = no goal saved yet — callers must show a no-goal state.
  Future<int> _userGoalMinutes() async {
    try {
      final json = await LocalStore.readProfile();
      if (json == null) return 0;
      final m = jsonDecode(json);
      if (m is! Map<String, dynamic>) return 0;
      return (m['daily_goal_minutes'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<ProgressSummary> summary() async {
    final attempts = await PracticeStore.loadAttempts();
    final goalMinutes = await _userGoalMinutes();
    if (attempts.isEmpty) {
      // Supabase fallback only when local history is empty.
      final client = supabaseOrNull;
      if (client != null) {
        try {
          final rows = await client.from('progress')
              .select('streak_days, chapters_done, average_score').limit(1);
          if (rows.isNotEmpty) {
            final r = rows.first;
            return ProgressSummary(streakDays: (r['streak_days'] as num?)?.toInt() ?? 0,
                chaptersDone: (r['chapters_done'] as num?)?.toInt() ?? 0,
                averageScore: (r['average_score'] as num?)?.toInt() ?? 0,
                totalAttempts: 0, totalCorrect: 0, totalAnswered: 0, xp: 0,
                level: 1, todayAnswered: 0, todayMinutes: 0,
                goalMinutes: goalMinutes,
                activityDates: [], weakChapters: [], attempts: []);
          }
        } catch (_) {}
      }
      // Cached server row from the sign-in restore: a fresh install
      // still shows progress when the server is unreachable now.
      // Live data above always wins; this is offline fallback only.
      final cached = await LocalStore.readServerProgress();
      if (cached != null) {
        return ProgressSummary(
            streakDays: cached['streak_days'] ?? 0,
            chaptersDone: cached['chapters_done'] ?? 0,
            averageScore: cached['average_score'] ?? 0,
            totalAttempts: 0, totalCorrect: 0, totalAnswered: 0, xp: 0,
            level: 1, todayAnswered: 0, todayMinutes: 0,
            goalMinutes: goalMinutes,
            activityDates: [], weakChapters: [], attempts: []);
      }
      return ProgressSummary.empty;
    }
    final dates = await PracticeStore.activityDates();
    final today = PracticeSession.today();
    var correct = 0, answered = 0, todayAnswered = 0, todaySeconds = 0;
    final wrongByChapter = <String, int>{};
    final totalByChapter = <String, int>{};
    final chaptersTouched = <String>{};
    // First question id seen per Bangla chapter label: the
    // English label is derived from THIS id (below), never from
    // a bank-only scan — guide ids live outside the banks, so
    // the old scan returned '' and the English label was empty
    // for every guide weak chapter.
    final repIdByChapter = <String, String>{};
    for (final a in attempts) {
      correct += a.correct;
      answered += a.answers.length;
      if (a.date == today) {
        todayAnswered += a.answers.length;
        todaySeconds += a.seconds;
      }
      if (a.chapter.isNotEmpty) chaptersTouched.add(a.chapter);
      // Phase 2: persisted wrong ids prove a guide answer wrong
      // even though findQuestion() cannot resolve guide ids.
      final persistedWrong = a.wrongItems.map((q) => q.id).toSet();
      for (final e in a.answers.entries) {
        final ch = practiceService.chapterOf(e.key, true);
        // Unparseable id -> no label, never a wrong one and
        // never a generic fallback ('General'): the answer
        // simply forms no weak chapter, matching chapterOf's
        // '' contract for unparseable ids.
        if (ch.isEmpty) continue;
        repIdByChapter.putIfAbsent(ch, () => e.key);
        totalByChapter[ch] = (totalByChapter[ch] ?? 0) + 1;
        final q = practiceService.findQuestion(e.key);
        if (persistedWrong.contains(e.key) ||
            (q != null && !q.isCorrect(e.value))) {
          wrongByChapter[ch] = (wrongByChapter[ch] ?? 0) + 1;
        }
      }
    }
    // Guide ids parse (via chapterOf's -ch<N>- pattern, the
    // same parsing the guide-quiz label uses) to a REAL label
    // in both languages: 'অধ্যায় ২' / 'Chapter 2', with Bangla
    // digits in Bangla — never an empty label for a parseable id.
    final weak = wrongByChapter.entries
        .map((e) => weakChapterFor(
            repIdByChapter[e.key] ?? '', e.value,
            totalByChapter[e.key] ?? e.value))
        .whereType<WeakChapter>()
        .toList()
      ..sort((a, b) => b.wrong.compareTo(a.wrong));
    final xp = correct * 10;
    return ProgressSummary(
      streakDays: PracticeStore.streakFrom(dates),
      chaptersDone: chaptersTouched.length,
      averageScore: answered == 0 ? 0 : correct * 100 ~/ answered,
      totalAttempts: attempts.length, totalCorrect: correct,
      totalAnswered: answered, xp: xp, level: 1 + xp ~/ 100,
      todayAnswered: todayAnswered, todayMinutes: todaySeconds ~/ 60,
      goalMinutes: goalMinutes,
      activityDates: dates, weakChapters: weak, attempts: attempts,
      weakItems: await practiceService.weakRevisionItems());
  }

  /// One weak chapter from a representative question id of the
  /// group (the first id seen for that chapter). Both labels
  /// come from that id via chapterOf, so a guide id yields its
  /// real parsed label in both languages instead of an empty
  /// English label from a bank-only lookup. Null = the id is
  /// unparseable: no label at all, never a wrong or generic one.
  WeakChapter? weakChapterFor(String repId, int wrong, int total) {
    final bn = practiceService.chapterOf(repId, true);
    if (bn.isEmpty) return null;
    return WeakChapter(
        bn, practiceService.chapterOf(repId, false), wrong, total);
  }

  Future<List<String>> savedQuestions() => LocalStore.savedQuestions();

  /// Phase 17 (L8): best-effort write to the `progress` table, which
  /// the app previously NEVER wrote (it only read it as a fallback).
  /// Pattern follows profile_service / saved_sync_service: the local
  /// attempt store is always the source of truth and is written first
  /// by the caller; this only ATTEMPTS a Supabase upsert of the
  /// freshly computed local summary (streak / chapters / average)
  /// and swallows failures, so local progress is kept on failure.
  /// No attempt without a signed-in Supabase user: the demo
  /// 'demo-user' id is not a uuid and would violate the table's
  /// user_id FK / RLS (auth.uid() = user_id). Callers invoke this
  /// after PracticeStore.saveAttempt, never before it.
  Future<void> syncToServer() async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    try {
      final sum = await summary();
      if (sum.totalAttempts == 0) return;
      await client.from('progress').upsert({
        'user_id': uid,
        'streak_days': sum.streakDays,
        'chapters_done': sum.chaptersDone,
        'average_score': sum.averageScore,
      }, onConflict: 'user_id');
    } catch (_) {}
  }
}

final progressService = ProgressService();
