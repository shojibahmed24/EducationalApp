// Guide-quiz sourcing: daily + practice quizzes from keyed guide
// MCQs via random-offset sampling (guide_quiz_sampling) + per-
// question Mode G key resolve. Phase 2 (2026-11-01): the old
// full-chapter download (fetchPool, ~277 sequential requests,
// permanent 40s-timeout fallback) is DELETED — sampling needs
// ~30 requests and never writes the chapter cache. Pool guards
// (key mapping, scorable filter, known-error ids) live in
// guide_quiz_pool.dart. Daily: seeded, 60 candidates, 20 items.
// Practice: random, seen-set excluded (refills when the unseen
// pool runs dry), 60 candidates, 20 items. Fewer than 20
// resolved items is NOT a fallback signal any more (plan §2
// step 2): the caller shows the shortfall honestly with an
// explicit bank button, never a silent substitution.
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backend_models.dart';
import 'guide_quiz_pool.dart';
import 'guide_quiz_sampling.dart';
import 'question_generation.dart';
import 'structured_explanation_service.dart';

export 'guide_quiz_pool.dart';

class GuideQuizService {
  static const _seenKey = 'guide_quiz_seen_ids';
  static const _seenCap = 200;

  /// Quiz size + selection headroom (plan §2 step 2).
  static const quizLimit = 20;
  static const selectionHeadroom = 60;

  /// Resolve Mode G keys for candidates in parallel batches of
  /// 5, in candidate order, until [limit] scored items are
  /// built. Drops (never guesses): missing grounding, empty
  /// key, unmapped letter, out-of-range index. Batch order is
  /// preserved, so a seeded candidate list yields a stable set.
  Future<List<QuizItem>> resolveKeys(
    List<GuideQuizCandidate> candidates, {
    required String subject,
    required int schoolClass,
    required bool bangla,
    required int limit,
  }) async {
    final items = <QuizItem>[];
    var at = 0;
    while (items.length < limit && at < candidates.length) {
      final batch = candidates.skip(at).take(5).toList();
      at += batch.length;
      final resolved = await Future.wait(batch.map((c) async {
        // Scoring-side exclusion (Phase 2 gap plan): bank rows
        // carry no solution by owner decision, so they are
        // never scored even if a caller passes unfiltered
        // candidates. The pool filter already excludes them;
        // this guard holds for direct resolveKeys callers too
        // (model-test list screen). Keyless rows are dropped
        // below via the empty-key check, unchanged.
        if (c.question.section == 'bank') return null;
        final grounding = await structuredExplanationService.resolveGuide(
          guideQuestionId: c.question.id,
          subject: subject,
          schoolClass: schoolClass,
          bangla: bangla,
        );
        final key = grounding.context?.answerKey ?? '';
        if (!grounding.found || key.isEmpty) return null;
        // Multi-key (Phase 2 gap plan): a JSON-list key maps to
        // every accepted option; a single key maps to one index,
        // exactly as before. Empty = no accepted option, dropped.
        final accepted = acceptedOptionIndices(
            parseAcceptedAnswerKeys(key), c.question.options);
        if (accepted.isEmpty) return null;
        return QuizItem(
          id: c.question.id,
          questionBn: c.question.questionText,
          questionEn: c.question.questionText,
          options: c.question.options,
          correctIndex: accepted.first,
          correctIndices: accepted,
        );
      }));
      for (final item in resolved) {
        if (item != null && items.length < limit) items.add(item);
      }
    }
    return items;
  }

  /// Daily guide set: seeded by date, stratified across chapters
  /// by the sampler's proportional allocation (same day + same
  /// data = same set). Returns up to 20 resolved items; fewer
  /// is the caller's shortfall case, never a bank fallback.
  Future<List<QuizItem>> dailyGuideQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
    required String day,
  }) async {
    final candidates = await guideQuizSampling.sample(
      subject: subject,
      schoolClass: schoolClass,
      want: selectionHeadroom,
      seedKey: questionGeneration.dailySeedKey(schoolClass, subject, day),
    );
    if (candidates.isEmpty) return const [];
    return resolveKeys(candidates,
        subject: subject, schoolClass: schoolClass,
        bangla: bangla, limit: quizLimit);
  }

  /// Practice guide set: random, seen-set excluded (refills
  /// when the unseen pool runs dry). Returns up to 20 resolved
  /// items; fewer is the caller's shortfall case.
  Future<List<QuizItem>> practiceGuideQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
  }) async {
    final seen = await _loadSeen();
    final candidates = await guideQuizSampling.sample(
      subject: subject,
      schoolClass: schoolClass,
      want: selectionHeadroom,
      seenIds: seen,
    );
    if (candidates.isEmpty) return const [];
    final items = await resolveKeys(candidates,
        subject: subject, schoolClass: schoolClass,
        bangla: bangla, limit: quizLimit);
    await _saveSeen({...seen, ...items.map((q) => q.id)});
    return items;
  }

  Future<Set<String>> _loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenKey)?.toSet() ?? {};
  }

  Future<void> _saveSeen(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.toList();
    final trimmed = list.length > _seenCap
        ? list.sublist(list.length - _seenCap)
        : list;
    await prefs.setStringList(_seenKey, trimmed);
  }
}

final guideQuizService = GuideQuizService();
