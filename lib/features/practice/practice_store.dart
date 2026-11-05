// Shared session + local persistence for Area 3 (practice/quiz/tests).
// DEMO mode: no backend keys needed. Results are stored in
// SharedPreferences (own keys below) so Progress reflects real runs.
// LocalStore is NOT edited: saved-question ids live under its existing
// 'saved_questions' key; unsave rewrites that same list via prefs.
// NOTE: no bKash here or anywhere in Area 3 — deliberately absent:
// Play Billing only, per the distribution decision.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/saved_sync_service.dart';

/// One finished run (quiz or model test), persisted as JSON.
class Attempt {
  final String kind; // 'quiz' or 'model'
  final String testId, subject, chapter;
  final int correct, total, seconds;
  final String date; // yyyy-mm-dd, local day the run finished
  final Map<String, int> answers; // questionId -> chosen option index
  // Batch 2 (item 5): question ids the user flagged for review during
  // the run. Empty for quiz runs and for attempts saved before this
  // field existed (fromJson defaults it to []).
  final List<String> flagged;
  // Phase 2 (2026-10-31): the run's ACTUAL wrong items, stored
  // whole (question + options + correct index). Guide items are
  // not in any bank, so without this the summary could not prove
  // a guide answer wrong and the revision quiz could not re-ask
  // it. Empty for attempts saved before this field existed.
  final List<QuizItem> wrongItems;
  const Attempt({
    required this.kind,
    required this.testId,
    required this.subject,
    required this.chapter,
    required this.correct,
    required this.total,
    required this.seconds,
    required this.date,
    required this.answers,
    this.flagged = const [],
    this.wrongItems = const [],
  });
  int get wrong => total - correct - skipped(answers, total);
  int get percent => total == 0 ? 0 : (correct * 100 ~/ total);
  int get xp => correct * 10;
  static int skipped(Map<String, int> a, int total) =>
      total - a.length; // unanswered = skipped
  Map<String, dynamic> toJson() => {
        'kind': kind, 'testId': testId, 'subject': subject,
        'chapter': chapter, 'correct': correct, 'total': total,
        'seconds': seconds, 'date': date,
        'answers': answers.map((k, v) => MapEntry(k, v)),
        'flagged': flagged,
        'wrongItems': wrongItems.map((q) => q.toJson()).toList(),
      };
  static Attempt fromJson(Map<String, dynamic> j) {
    final raw = (j['answers'] as Map?) ?? {};
    final fl = j['flagged'];
    final wi = j['wrongItems'];
    return Attempt(
      kind: j['kind'] as String? ?? 'quiz',
      testId: j['testId'] as String? ?? '',
      subject: j['subject'] as String? ?? '',
      chapter: j['chapter'] as String? ?? '',
      correct: (j['correct'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? 0,
      seconds: (j['seconds'] as num?)?.toInt() ?? 0,
      date: j['date'] as String? ?? '',
      answers: raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      flagged: fl is List ? fl.map((e) => e.toString()).toList() : const [],
      wrongItems: wi is List
          ? wi
              .whereType<Map>()
              .map((e) => QuizItem.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v))))
              .toList()
          : const [],
    );
  }
}

/// In-memory session: what the next screen should show. The results
/// screens read this first, then fall back to the last saved attempt,
/// so a direct deep-link never shows another run's numbers.
class PracticeSession {
  static String selectedSubject = 'math';
  static List<QuizItem> quizItems = [];
  // Batch 2 (items 8/9): where the current quiz set came from.
  // 'bankFallback' = the labelled practice bank (today's only
  // scorable pool); 'book' = book-verified scorable pool (does
  // not exist yet — see QUESTION_GENERATION.md). quizIsRevision
  // marks a weak-topic revision set (actual wrong answers only).
  static String quizSource = 'bankFallback';
  static bool quizIsRevision = false;

  /// Phase 2: the current quiz set's guide shortfall (0 = full
  /// or bank set) and its seedKey (for the quiz screen's bank
  /// button, which rebuilds the bank set with the same seed).
  static int quizShortfall = 0;
  static String quizSeedKey = '';
  static List<QuizItem> modelItems = [];
  static String modelTestId = '', modelSubject = '', modelChapter = '';
  static int modelMinutes = 15; // matches the default (maths) test

  /// Phase 2: true when the running exam is a GUIDE model-test
  /// set (Ask-AI enabled via the guide-chat path); false for
  /// bank model tests (no Ask-AI button — no guide row exists).
  static bool modelIsGuide = false;

  /// Phase 2: in-memory exam progress, so opening Ask-AI chat
  /// (a route change that disposes the exam screen) and coming
  /// back restores answers, flags, clock and position instead
  /// of restarting the timed exam. Cleared on submit and on
  /// every fresh exam start.
  static String modelExamTestId = '';
  static Map<int, int> modelExamAnswers = {};
  static Set<int> modelExamFlagged = {};
  static int modelExamSecondsLeft = -1;
  static int modelExamIndex = 0;

  static void saveModelExam({
    required Map<int, int> answers,
    required Set<int> flagged,
    required int secondsLeft,
    required int index,
  }) {
    modelExamTestId = modelTestId;
    modelExamAnswers = Map<int, int>.from(answers);
    modelExamFlagged = Set<int>.from(flagged);
    modelExamSecondsLeft = secondsLeft;
    modelExamIndex = index;
  }

  static void clearModelExam() {
    modelExamTestId = '';
    modelExamAnswers = {};
    modelExamFlagged = {};
    modelExamSecondsLeft = -1;
    modelExamIndex = 0;
  }
  static Attempt? lastAttempt;
  static List<QuizItem> lastItems = [];
  // Phase 17 (L3): one-shot flag — the model-test exam sets this
  // when it auto-submits at time-up, so the results screen can show
  // the time-up message on the screen itself instead of relying only
  // on a snackbar shown just before navigation (easily missed).
  // The results screen reads and clears it on first build.
  static bool timeUpAutoSubmit = false;
  static String today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}'
        '-${n.day.toString().padLeft(2, '0')}';
  }
}

/// Local persistence helper (Area 3 only).
class PracticeStore {
  static const _attemptsKey = 'ys_attempts_json';
  static const _activityKey = 'ys_activity_dates';
  static const _savedKey = 'saved_questions'; // LocalStore's key, reused

  static Future<List<Attempt>> loadAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Attempt.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Attempt> saveAttempt(Attempt a) async {
    // Batch 2 (item 4 root cause): the in-memory attempt is set FIRST,
    // so a later disk failure can never leave the results screen
    // without the run. The lists below are copied before mutation:
    // activityDates() used to return SharedPreferences' own list (or
    // the const [] fallback when the key did not exist yet), and
    // dates.add() on it threw UnsupportedError on EVERY submit —
    // the activity key was never written, so the crash repeated on
    // every attempt, before lastAttempt was set and before the exam
    // screen navigated anywhere.
    PracticeSession.lastAttempt = a;
    final prefs = await SharedPreferences.getInstance();
    final list = List<Attempt>.from(await loadAttempts())..add(a);
    await prefs.setString(
        _attemptsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    final dates = List<String>.from(await activityDates());
    if (!dates.contains(a.date)) {
      dates.add(a.date);
      await prefs.setStringList(_activityKey, dates);
    }
    return a;
  }

  static Future<List<String>> activityDates() async {
    final prefs = await SharedPreferences.getInstance();
    // Mutable copy: callers may add to the result (see saveAttempt).
    return List<String>.from(prefs.getStringList(_activityKey) ?? const []);
  }

  /// Consecutive active days ending today (or yesterday, if today has
  /// no activity yet — a streak is not broken mid-day).
  static int streakFrom(List<String> dates) {
    final set = dates.toSet();
    var day = DateTime.now();
    if (!set.contains(PracticeSession.today())) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}'
          '-${day.day.toString().padLeft(2, '0')}';
      if (!set.contains(key)) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Remove a saved question id for real (same 'saved_questions'
  /// key LocalStore.unsaveQuestion writes; kept for this screen).
  static Future<void> unsaveQuestion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    // Same unmodifiable-list fix as saveAttempt: copy before remove.
    final list = List<String>.from(prefs.getStringList(_savedKey) ?? const []);
    final removed = list.remove(id);
    await prefs.setStringList(_savedKey, list);
    // Phase 16 (M10): mirror the unsave to the cloud when signed in.
    if (removed) await savedSyncService.syncUnsave(id);
  }
}
