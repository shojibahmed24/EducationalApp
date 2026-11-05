// Practice / quiz data + attempt saving. Daily quiz tries keyed
// guide MCQs first; the bank is NEVER a silent substitute any
// more (Phase 2, plan §2 step 2): a short guide set ships with
// its shortfall, an empty guide set ships empty, and the SCREEN
// asks the user before starting a bank set. Book rows (Edge Mode
// D, no options/answers) NEVER become scored items — see
// QUESTION_GENERATION.md. Attempts go to quiz_attempts when a
// backend exists, AND always locally. No bKash — Play only.
// Fixed-count model tests moved to model_test_service.dart.
import '../models/backend_models.dart';
import 'guide_quiz_service.dart';
import 'local_store.dart';
import 'practice_banks.dart';
import 'question_bank.dart';
import 'question_generation.dart';
import 'supabase_client.dart';
import '../../features/practice/practice_store.dart';

class PracticeService {
  // Banks live in practice_banks.dart (stable ids; saved/weak logic keys on them).
  List<QuizItem> mathQuiz() => PracticeBanks.mathQuiz();
  List<QuizItem> scienceQuiz() => PracticeBanks.scienceQuiz();

  List<QuizItem> quizFor(String subject) =>
      subject == 'science' ? scienceQuiz() : mathQuiz();

  /// Saved question's subject from its BANK (ids stored bare):
  /// mq/mm/mp = maths, sq/sm/sp = science; else null (never guess).
  String? subjectOf(String id) {
    if (id.startsWith('mq') || id.startsWith('mm') || id.startsWith('mp')) return 'math';
    if (id.startsWith('sq') || id.startsWith('sm') || id.startsWith('sp')) return 'science';
    return null;
  }

  List<QuizItem> modelMath() => PracticeBanks.modelMath();
  List<QuizItem> modelScience() => PracticeBanks.modelScience();

  /// Bank quiz set: up to [count] questions (Phase 2 size 20),
  /// seeded per day. Sync, no network. A 5-item bank pool
  /// yields 5 items — the pool is never padded by repetition.
  List<QuizItem> dailyQuizFor(String subject,
          {String? seedKey, int count = 20}) =>
      questionGeneration.selectQuestions(
          pool: quizFor(subject), count: count,
          seedKey: seedKey ?? 'daily-$subject-${PracticeSession.today()}',
          chapterOf: (q) => chapterOf(q.id, true));

  List<PracticeProblem> practiceFor(String subject) => subject == 'science'
      ? const [PracticeProblem(id: 'sp1', questionBn: 'বেগ নির্ণয়ের সূত্র লেখো।',
          questionEn: 'Write the formula for velocity.',
          answerBn: 'বেগ = দূরত্ব ÷ সময়।', answerEn: 'Velocity = distance ÷ time.')]
      : const [PracticeProblem(id: 'mp1',
          questionBn: '৩:৫ অনুপাতে ৪০টি কলম ভাগ করলে কয়টি করে পাবে?',
          questionEn: 'Divide 40 pens in ratio 3:5. How many each?',
          answerBn: 'মোট ৮ ভাগ, প্রতি ভাগ ৫টি — ১৫টি ও ২৫টি।',
          answerEn: 'Total 8 parts, 5 each — 15 and 25.')];

  /// DEMO-ONLY bank solutions (mq/sq), NOT book-verified/AI;
  /// labelled DEMO fallback only — a live no-match NEVER falls back here.
  String explanation(String id, bool bangla) =>
      bankExplanation(id, bangla);

  /// Test seam: default delegates to the real services; tests
  /// override them to throw/hang, proving the fallbacks below.
  Future<List<BookQuestion>?> fetchBookProbe({
    required String subject, required int schoolClass, required bool bangla,
  }) => questionGeneration.fetchBookQuestions(
      subject: subject, schoolClass: schoolClass, bangla: bangla);

  Future<List<QuizItem>> fetchGuideDaily({
    required String subject, required int schoolClass, required bool bangla,
    required String day,
  }) => guideQuizService.dailyGuideQuiz(
      subject: subject, schoolClass: schoolClass, bangla: bangla, day: day);

  Future<List<QuizItem>> fetchPracticeGuide({
    required String subject, required int schoolClass, required bool bangla,
  }) => guideQuizService.practiceGuideQuiz(
      subject: subject, schoolClass: schoolClass, bangla: bangla);

  /// Daily quiz: guide set of up to 20, never silently bank.
  /// Guide throw/timeout -> EMPTY guide items (the screen asks
  /// the user about a bank set; the service never substitutes).
  /// A short guide set ships with its guideShortfall; an empty
  /// guide set ships empty with shortfall 20. RESILIENCE: book
  /// probe is best-effort (throw/timeout -> 0, never aborts).
  /// Service timeouts sit below the screens' 60s outer timeout.
  Future<GeneratedSet> generateDailyQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
    String? day,
    Duration bookProbeTimeout = const Duration(seconds: 10),
    Duration guideTimeout = const Duration(seconds: 40),
  }) async {
    final d = day ?? PracticeSession.today();
    final seedKey = questionGeneration.dailySeedKey(schoolClass, subject, d);
    List<BookQuestion>? book;
    try {
      book = await fetchBookProbe(subject: subject, schoolClass: schoolClass, bangla: bangla).timeout(bookProbeTimeout);
    } catch (_) { book = null; }
    List<QuizItem> guideItems;
    try {
      guideItems = await fetchGuideDaily(subject: subject, schoolClass: schoolClass, bangla: bangla, day: d).timeout(guideTimeout);
    } catch (_) { guideItems = []; }
    return GeneratedSet(
        items: guideItems,
        source: QuestionSource.guide,
        seedKey: seedKey,
        bookQuestionsIndexed: book?.length ?? 0,
        guideShortfall: GuideQuizService.quizLimit - guideItems.length);
  }

  /// Subject practice: same guide-first, never-silent rule as
  /// daily (guide call guarded: throw/timeout -> empty guide
  /// set, shortfall 20). Scoring and filtering unchanged.
  Future<GeneratedSet> generatePracticeQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
    Duration guideTimeout = const Duration(seconds: 40),
  }) async {
    List<QuizItem> guideItems;
    try {
      guideItems = await fetchPracticeGuide(subject: subject, schoolClass: schoolClass, bangla: bangla).timeout(guideTimeout);
    } catch (_) { guideItems = []; }
    return GeneratedSet(
        items: guideItems,
        source: QuestionSource.guide,
        seedKey: 'practice-$subject-${PracticeSession.today()}',
        bookQuestionsIndexed: 0,
        guideShortfall: GuideQuizService.quizLimit - guideItems.length);
  }

  /// Weak revision: the user's ACTUAL wrong answers, newest first,
  /// deduped; unresolvable ids skipped, never substituted.
  /// Phase 2: persisted wrongItems first (guide items are not in
  /// any bank); bank resolution only for pre-wrongItems attempts.
  Future<List<QuizItem>> weakRevisionItems() async {
    final attempts = await PracticeStore.loadAttempts();
    final seen = <String>{};
    final out = <QuizItem>[];
    for (final a in attempts.reversed) {
      for (final q in a.wrongItems) {
        if (seen.add(q.id)) out.add(q);
      }
      for (final e in a.answers.entries) {
        if (seen.contains(e.key)) continue;
        final q = findQuestion(e.key);
        if (q == null || q.isCorrect(e.value)) continue;
        if (seen.add(q.id)) out.add(q);
      }
    }
    return out;
  }

  /// Chapter label for an id: guide ids parse to their REAL
  /// chapter; bank ids to their coarse chapter; else '' (no label,
  /// never a wrong one) — callers omit the chapter line.
  String chapterOf(String id, bool bangla) {
    final guide = _guideChapter(id, bangla);
    if (guide != null) return guide;
    if (id.startsWith('mq') || id.startsWith('mm')) {
      return bangla ? 'গণিত · পরিমাপ ও অনুপাত' : 'Maths · Measurement & Ratio';
    }
    if (id.startsWith('sq') || id.startsWith('sm')) {
      return bangla ? 'বিজ্ঞান · গতি ও পদার্থ' : 'Science · Motion & Matter';
    }
    return '';
  }

  /// '...-guide-ch2-...' -> 'অধ্যায় ২' / 'Chapter 2'; null if unparseable.
  String? _guideChapter(String id, bool bangla) {
    final m = RegExp(r'-ch(\d+)-').firstMatch(id);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null) return null;
    return bangla ? 'অধ্যায় ${_bnDigits('$n')}' : 'Chapter $n';
  }

  String _bnDigits(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) { final d = int.tryParse(c); return d == null ? c : bn[d]; }).join();
  }

  QuizItem? findQuestion(String id) {
    for (final q in [...mathQuiz(), ...scienceQuiz(), ...modelMath(), ...modelScience()]) {
      if (q.id == id) return q;
    }
    return null;
  }

  Future<Attempt> recordAttempt(Attempt a) async {
    await PracticeStore.saveAttempt(a);
    final client = supabaseOrNull;
    if (client != null) {
      try {
        await client.from('quiz_attempts').insert(
            {'test_id': a.testId, 'score': a.correct, 'total': a.total});
      } catch (_) {/* local copy saved; sync retry is review work */}
    }
    return a;
  }

  Future<void> saveAttempt({required String testId, required int score, required int total}) async {
    await recordAttempt(Attempt(kind: 'quiz', testId: testId, subject: '',
        chapter: '', correct: score, total: total, seconds: 0,
        date: PracticeSession.today(), answers: {}));
  }

  /// True only when [id] was newly saved (H3).
  Future<bool> saveQuestion(String id) => LocalStore.saveQuestion(id);
}

final practiceService = PracticeService();
