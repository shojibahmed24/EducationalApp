// Structured solution path (locked 2026-10-29): the lesson
// screen's live-AI path, returning a parsed StructuredSolution
// instead of a wall of text. The caller guarantees grounding
// (an already-resolved Grounding); this file never guesses.
// Policy enforced here, not in prompts alone:
//  - Marks budget: prompt budget + one retry when far off-band.
//  - Duplicate guard: a summary identical to finalAnswer is a
//    bad draft — one strict retry; if still identical, the
//    solution is kept and the renderer hides the duplicate
//    summary card (never two copies of the same text).
//  - Key gate: an MCQ draft must name the SAME OPTION as the
//    stored printed key — by label or option text, never by
//    exact string (2026-11-03: the old raw-string gate threw
//    away agreeing drafts written in the other label system).
//    On a genuine different-option mismatch the draft is
//    discarded (caller shows the key instead) — never the reverse.
//  - Hidden grounding: guideUnitText goes into the prompt ONLY
//    and is never returned for display.
//  - Fallback: unparseable twice => failed, but a truncated-JSON
//    reply salvages its complete step texts as prose; the caller
//    renders the old plain-text path, never a blank screen.
//  - Slowness retry (2026-11-01): a failed first attempt retries
//    with a halved budget + trimmed grounding, because live
//    probes show long Bengali structured output timing out on
//    the slow free model — an identical retry cannot help.
import 'dart:convert';

import '../models/backend_models.dart';
import '../models/solution_model.dart';
export '../models/solution_model.dart' show StructuredAttempt, StructuredStatus;
import 'app_config.dart';
import 'edge_post.dart';
import 'explanation_script_guard.dart';
import 'explanation_service.dart';
import 'marks_budget.dart';
import 'openrouter_client.dart';
import 'structured_parse.dart';
import 'structured_prompts.dart';
import 'supabase_client.dart';

class StructuredExplanationService {
  /// [marksOverride] is the chat worker's user-stated marks
  /// (parseUserMarks of the student's message). It replaces the
  /// printed ctx.marks for the budget ONLY; null (the lesson
  /// path) leaves the printed-marks path untouched, and the
  /// override is never displayed as printed marks.
  Future<StructuredAttempt> explainStructured({
    required Grounding grounding,
    required String style,
    required bool bangla,
    String? userQuestion,
    int? marksOverride,
  }) async {
    final ctx = grounding.context;
    if (!grounding.found || ctx == null) {
      return const StructuredAttempt(status: StructuredStatus.failed);
    }
    if (!AppConfig.aiTextConfigured) {
      return const StructuredAttempt(status: StructuredStatus.failed);
    }
    var budget = marksBudgetFor(
      marks: marksOverride ?? ctx.marks,
      questionType: ctx.questionType.isEmpty ? 'textbook' : ctx.questionType,
    );
    // 'short' is an explicit user override: tighten the band by
    // one step (never below 2). Other styles change wording only.
    if (style == 'short') {
      budget = MarksBudget(
        marks: budget.marks,
        maxSteps: (budget.maxSteps - 1).clamp(2, budget.maxSteps),
        maxLines: budget.maxLines,
        guidance: budget.guidance,
      );
    }
    var attempt = await _tryOnce(
      ctx: ctx, style: style, bangla: bangla, budget: budget,
      userQuestion: userQuestion, strict: false,
    );
    // A garbled ok (mixed-script or foreign-script words) is
    // failed, so the trimmed retry below runs instead of
    // showing the garbage to the student.
    attempt = _sanitized(attempt);
    if (attempt.status == StructuredStatus.failed) {
      // 2026-11-01: a failed first attempt on a long Bengali
      // prompt is (per live probes) a slow-model timeout/drop,
      // NOT a wording problem — an identical retry cannot help.
      // So this retry halves the budget AND trims grounding,
      // shrinking prompt + JSON output. Quality retries below
      // (key-mismatch / duplicate) keep the full budget.
      final trimmedBudget = MarksBudget(
        marks: budget.marks,
        maxSteps: (budget.maxSteps ~/ 2).clamp(2, budget.maxSteps),
        maxLines: (budget.maxLines ~/ 2).clamp(4, budget.maxLines),
        guidance: budget.guidance,
      );
      attempt = await _tryOnce(
        ctx: ctx, style: style, bangla: bangla, budget: trimmedBudget,
        userQuestion: userQuestion, strict: true, trimmed: true,
      );
    } else if (attempt.status == StructuredStatus.keyMismatch) {
      final retry = await _tryOnce(
        ctx: ctx, style: style, bangla: bangla, budget: budget,
        userQuestion: userQuestion, strict: true,
      );
      if (retry.status == StructuredStatus.ok) attempt = retry;
    } else if (attempt.solution != null &&
        (summaryEqualsFinal(attempt.solution!.summary,
                attempt.solution!.finalAnswer) ||
            stepsFarOffBudget(attempt.solution!.steps.length, budget))) {
      final retry = await _tryOnce(
        ctx: ctx, style: style, bangla: bangla, budget: budget,
        userQuestion: userQuestion, strict: true,
      );
      // A still-duplicate retry is kept, not discarded: the
      // renderer hides the duplicate summary card instead.
      if (retry.status == StructuredStatus.ok) attempt = retry;
    }
    // Backstop: a garbled ok from any retry path never leaves
    // this method as ok — the UI shows the honest note.
    return _sanitized(attempt);
  }

  /// Maps a garbled ok attempt to failed; everything else passes.
  StructuredAttempt _sanitized(StructuredAttempt attempt) {
    if (attempt.status == StructuredStatus.ok &&
        attempt.solution != null &&
        solutionHasScriptGarbage(attempt.solution!)) {
      return const StructuredAttempt(status: StructuredStatus.failed);
    }
    return attempt;
  }

  Future<StructuredAttempt> _tryOnce({
    required GroundedContext ctx,
    required String style,
    required bool bangla,
    required MarksBudget budget,
    required bool strict,
    String? userQuestion,
    bool trimmed = false,
  }) async {
    final gen = await openRouterClient.chatRaw(
      systemPrompt: structuredSystemPrompt(bangla, budget, strict),
      userPrompt: structuredUserPrompt(ctx, style, userQuestion,
          trimmed: trimmed),
    );
    final raw = gen.text;
    if (raw == null || raw.isEmpty) {
      return const StructuredAttempt(status: StructuredStatus.failed);
    }
    // Fences are stripped BEFORE any fallback use, so raw JSON /
    // fences never reach the user. Unparseable prose still falls
    // back as text; unparseable JSON salvages only its complete
    // step texts as prose (never broken JSON, never invented
    // summary/finalAnswer) — previously it was discarded outright
    // (rawText ''), so a truncated model reply always showed the
    // failed row even when usable steps had arrived.
    final cleaned = stripStructuredFences(raw);
    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      final looksJson =
          cleaned.startsWith('{') || cleaned.startsWith('[');
      return StructuredAttempt(
        status: StructuredStatus.failed,
        rawText: looksJson ? salvageTruncatedJsonText(cleaned) : cleaned,
        aiProvider: gen.provider,
        aiModel: gen.model,
      );
    }
    // Strict contract first; a single bad step falls back to the
    // lenient partial parse, which keeps the valid steps.
    final solution =
        parseStructuredSolution(decoded) ??
            parsePartialStructuredSolution(decoded);
    if (solution == null) {
      return const StructuredAttempt(status: StructuredStatus.failed);
    }
    if (ctx.answerKey.isNotEmpty &&
        !solutionMatchesKey(solution, ctx.answerKey, ctx.options)) {
      return StructuredAttempt(
        status: StructuredStatus.keyMismatch,
        storedKey: ctx.answerKey,
        aiProvider: gen.provider,
        aiModel: gen.model,
      );
    }
    return StructuredAttempt(
      status: StructuredStatus.ok,
      solution: solution,
      aiProvider: gen.provider,
      aiModel: gen.model,
    );
  }

  /// Guide Mode G resolution (Edge Function, code only — the
  /// function is NOT deployed by this change). Returns
  /// not-indexed when the guide row is absent, edge-missing
  /// when no server path exists.
  Future<Grounding> resolveGuide({
    required String guideQuestionId,
    required String subject,
    required int schoolClass,
    required bool bangla,
  }) async {
    if (supabaseOrNull == null || AppConfig.explainEndpoint.isEmpty) {
      return const Grounding(reason: 'edge-missing');
    }
    final res = await edgePost({
      'guideQuestionId': guideQuestionId,
      'language': bangla ? 'bn' : 'en',
    });
    if (res == null) return const Grounding(reason: 'edge-missing');
    if (res['found'] != true) return Grounding.notIndexed;
    final ctx = _guideContextFrom(res, subject, schoolClass);
    if (ctx == null) return Grounding.notIndexed;
    return Grounding(context: ctx, reason: 'found');
  }

  GroundedContext? _guideContextFrom(
    Map<String, dynamic> res, String subject, int schoolClass) {
    final questionText = res['questionText'];
    if (questionText is! String || questionText.isEmpty) return null;
    final marks = (res['marks'] as num?)?.toInt();
    final chunks = ((res['textbookChunks'] as List?) ?? [])
        .whereType<Map>()
        .where((c) => c['text'] is String)
        .toList();
    final fallback = res['fallbackChunk'];
    return GroundedContext(
      bookTitle: '${res['bookTitle'] ?? ''}',
      chapterTitle: '${res['chapterTitle'] ?? ''}',
      subject: subject,
      schoolClass: schoolClass,
      chapterNumber: (res['chapterNumber'] as num?)?.toInt() ?? 0,
      page: 0,
      problem: 0,
      questionText: questionText,
      source: 'guide',
      chunkTexts: chunks.map((c) => c['text'] as String).toList(),
      chunkPageRanges: chunks.map((c) {
        final s = c['pageStart'], e = c['pageEnd'];
        return s is num && e is num ? '${s.toInt()}–${e.toInt()}' : '';
      }).toList(),
      guideQuestionId: '${res['guideQuestionId'] ?? ''}',
      questionType: '${res['questionType'] ?? ''}',
      answerKey: '${res['answerKey'] ?? ''}',
      guideUnitText: '${res['groundingSolution'] ?? ''}',
      guideUnitKind: '${res['unitKind'] ?? ''}',
      verbatimKind: '${res['verbatimKind'] ?? 'none'}',
      verbatimText: '${res['verbatimText'] ?? ''}',
      correctionNote: '${res['correctionNote'] ?? ''}',
      guideExplanation: '${res['guideExplanation'] ?? ''}',
      guideError: res['guideError'] == true,
      // 2026-11-03 fix: Mode G now returns the exact option texts
      // + the row's own stimulus; both ride into the prompt
      // (verbatim options, labeled stimulus block). Absent = [].
      options: ((res['options'] as List?) ?? []).map((e) => '$e').toList(),
      stimulusText: '${res['stimulusText'] ?? ''}',
      stimulusRef: '${res['stimulusRef'] ?? ''}',
      fallbackChunkText: fallback is Map && fallback['text'] is String
          ? fallback['text'] as String
          : '',
      marks: marks,
    );
  }

}

final structuredExplanationService = StructuredExplanationService();
