// Guide-quiz pool guards (pure, offline): key-letter mapping, the
// scorable-pool filter, and the known guide-error ids. Split out
// of guide_quiz_service.dart to keep that file under the 250-line
// cap (Phase 2). No Edge calls here — sampling lives in
// guide_quiz_sampling.dart, key resolution in guide_quiz_service.
import 'dart:convert';

import '../models/guide_bank_model.dart';

/// Option letters in Edge order (optionsToArray: ক,খ,গ,ঘ,ঙ).
const _optionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

/// Known guide-error MCQ ids (Math class 7 pilot corrections
/// log, kind guide_error_mcq): their printed keys are wrong, so
/// they must NEVER be scored. Public so tests can assert all
/// 18 are excluded; kept alongside the server flag as the
/// pre-deploy guard for servers not yet sending guideError.
const knownGuideErrorIds = {
  'class7-math-bn-guide-ch2-p44-ex21-mcq18',
  'class7-math-bn-guide-ch2-p56-ex22b-mcq17',
  'class7-math-bn-guide-ch3-p86-mcq26',
  'class7-math-bn-guide-ch3-p87-mcq51',
  'class7-math-bn-guide-ch4-p107-mcq13',
  'class7-math-bn-guide-ch5-p125-mcq34',
  'class7-math-bn-guide-ch6-p153-ex61mcq9',
  'class7-math-bn-guide-ch7-p182-ex72mcq10',
  'class7-math-bn-guide-ch7-p182-ex72mcq11',
  'class7-math-bn-guide-ch8-p200-ex8mcq2',
  'class7-math-bn-guide-ch8-p201-ex8smcq31',
  'class7-math-bn-guide-ch9-p211-ex91smcq59',
  'class7-math-bn-guide-ch9-p211-ex91smcq61',
  'class7-math-bn-guide-ch9-p221-ex92smcq32',
  'class7-math-bn-guide-ch10-p242-ex101smcq12',
  'class7-math-bn-guide-ch10-p242-ex101smcq30',
  'class7-math-bn-guide-ch10-p249-ex102smcq26',
  'class7-math-bn-guide-ch11-p274-ex11mcq2',
};

/// Letter (ক/খ/গ/ঘ/ঙ) -> option index, or null when the letter
/// is unknown or outside the option list. Never guess.
int? guideKeyIndex(String letter, int optionCount) {
  final i = _optionLetters.indexOf(letter);
  if (i < 0 || i >= optionCount) return null;
  return i;
}

/// True when a list row may enter a scored quiz pool: MCQ with
/// a server-confirmed key and options, and neither a
/// server-flagged guide-error row nor a known guide-error id.
/// Chapter-bank rows only: model-test set rows (setId != null)
/// never enter the daily/practice pool. Unkeyed rows are
/// excluded here, before any selection or scoring can see them.
/// Bank-section rows are excluded outright (Phase 2 gap plan):
/// they carry no solution by owner decision, so they must never
/// be scored even if a server ever reported a key for one. The
/// NULL-key case is covered by serverHasKey (a NULL answer_key
/// yields hasKey false), pinned by tests alongside the bank
/// guard so both exclusions stay explicit.
bool isScorableGuideMcq(GuideBankQuestion q) =>
    q.questionType == 'mcq' &&
    q.serverHasKey &&
    q.options.isNotEmpty &&
    !q.guideError &&
    q.setId == null &&
    q.section != 'bank' &&
    !knownGuideErrorIds.contains(q.id);

/// Parse a Mode G answerKey into accepted variants (Phase 2
/// gap plan, multi-key scoring). A JSON-encoded list decodes
/// to its variants (Paper-II: 134 rows carry a JSON list of
/// acceptable answers for one item). Anything else is one
/// variant: a bare letter (ক/খ/গ/ঘ), a word, or a full
/// sentence key. Empty input yields no variants; unparseable
/// input degrades to a single literal variant, never a guess —
/// it simply matches no option downstream.
List<String> parseAcceptedAnswerKeys(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return [decoded.trim()];
    }
  } catch (_) {
    // Not JSON: fall through to single-variant treatment.
  }
  return [trimmed];
}

/// Map accepted variants to option indices. A variant that is
/// a single option letter maps by Edge order (guideKeyIndex);
/// any other variant maps to options whose text matches it
/// exactly after trimming. Matching is exact on purpose:
/// near-matches are never guessed. Returns sorted unique
/// indices; empty when no variant matches any option.
List<int> acceptedOptionIndices(
  List<String> variants,
  List<String> options,
) {
  final out = <int>{};
  for (final v in variants) {
    final letter = guideKeyIndex(v, options.length);
    if (letter != null) {
      out.add(letter);
      continue;
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].trim() == v.trim()) out.add(i);
    }
  }
  final sorted = out.toList()..sort();
  return sorted;
}

/// True when a single-select answer is acceptable: the selected
/// option index is one of the accepted indices. This is the
/// multi-key rule — ANY listed variant earns full marks.
/// Single-variant questions pass a one-element list, so the
/// rule is uniform and the old single-index check is the
/// one-element case of it.
bool isAcceptedOptionIndex(int selected, List<int> accepted) =>
    accepted.contains(selected);

/// A pool row with its textbook chapter (for stratification).
class GuideQuizCandidate {
  final GuideBankQuestion question;
  final int chapter;
  const GuideQuizCandidate(this.question, this.chapter);
}

/// Largest-remainder allocation of [want] across chapter totals
/// (pure, tested): shares proportional to totals, capped at each
/// chapter's total, remainder distributed to largest fractions.
List<int> allocateProportional(List<int> totals, int want) {
  final sum = totals.fold(0, (a, b) => a + b);
  final alloc = List<int>.filled(totals.length, 0);
  if (sum <= 0 || want <= 0) return alloc;
  var assigned = 0;
  final frac = <int, double>{};
  for (var i = 0; i < totals.length; i++) {
    final exact = want * totals[i] / sum;
    var a = exact.floor();
    if (a > totals[i]) a = totals[i];
    alloc[i] = a;
    assigned += a;
    frac[i] = exact - a;
  }
  // Remainder goes to the largest fractional shares that still
  // have headroom; capped chapters never receive more.
  final order = frac.keys.toList()
    ..sort((a, b) => frac[b]!.compareTo(frac[a]!));
  var left = want - assigned;
  var guard = 0;
  while (left > 0 && guard < totals.length * 2) {
    guard++;
    var moved = false;
    for (final i in order) {
      if (left <= 0) break;
      if (alloc[i] < totals[i]) {
        alloc[i]++;
        left--;
        moved = true;
      }
    }
    if (!moved) break;
  }
  return alloc;
}
