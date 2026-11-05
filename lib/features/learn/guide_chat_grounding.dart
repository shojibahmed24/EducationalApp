// Chat grounding dispatch, split out of chat_screen.dart to keep
// that file under the 250-line cap. Guide selections (opened
// from a guide answer) resolve via Mode G (resolveGuide, the
// same path the step-by-step explanation already uses) and
// NEVER touch the textbook index — page/problem 0 is not a
// lesson lookup. Textbook selections keep the exact old dispatch
// (by-id, else page/problem resolve).
import '../../core/models/backend_models.dart';
import '../../core/services/explanation_service.dart';
import '../../core/services/structured_explanation_service.dart';
import 'lesson_grounding.dart';
import 'lesson_selection.dart';

/// Resolved grounding plus whether it came from a guide row.
class ChatGrounding {
  const ChatGrounding(this.grounding, this.isGuide);
  final Grounding grounding;
  final bool isGuide;
}

/// Chat-only context overlay (2026-11-03 fix, replaces the old
/// stimulus prepend). The resolved Mode G context gains:
///  - the selection's stimulus, ONLY when it belongs to the
///    resolved question (stimulusQuestionId == guideQuestionId;
///    legacy selections without an owner id fall back to the
///    selection's own question id). A wrong/stale stimulus can
///    never leak into this chat's prompt.
///  - the selection's verbatim options when Mode G returned none
///    (list rows carry options; id-only opens rely on Mode G).
/// The stimulus rides as its OWN field, never fused into
/// questionText: prompts render it as a labeled context block,
/// so a bare-word MCQ ("shriek") can no longer read as "only
/// stimulus given, no question". Mode G's own stimulus wins
/// over the selection's when both exist (same row, freshest
/// truth). Previously dropped fields (guideExplanation, marks)
/// are carried through.
Grounding withChatStimulus(Grounding grounding, LessonSelection sel) {
  final ctx = grounding.context;
  if (ctx == null) return grounding;
  final owned = sel.stimulusQuestionId != null
      ? sel.stimulusQuestionId == ctx.guideQuestionId
      : (ctx.guideQuestionId.isEmpty ||
          sel.guideQuestionId == ctx.guideQuestionId);
  final selStim = owned ? (sel.stimulusText?.trim() ?? '') : '';
  final stimulus =
      ctx.stimulusText.isNotEmpty ? ctx.stimulusText : selStim;
  final options = ctx.options.isNotEmpty ? ctx.options : sel.guideOptions;
  final optionsSame = options.length == ctx.options.length &&
      List.generate(options.length, (i) => options[i] == ctx.options[i])
          .every((e) => e);
  if (stimulus == ctx.stimulusText && optionsSame) {
    return grounding;
  }
  return Grounding(
    context: GroundedContext(
      bookTitle: ctx.bookTitle,
      chapterTitle: ctx.chapterTitle,
      subject: ctx.subject,
      schoolClass: ctx.schoolClass,
      chapterNumber: ctx.chapterNumber,
      page: ctx.page,
      problem: ctx.problem,
      questionText: ctx.questionText,
      localAnswer: ctx.localAnswer,
      source: ctx.source,
      chunkTexts: ctx.chunkTexts,
      chunkPageRanges: ctx.chunkPageRanges,
      guideQuestionId: ctx.guideQuestionId,
      questionType: ctx.questionType,
      answerKey: ctx.answerKey,
      guideUnitText: ctx.guideUnitText,
      guideUnitKind: ctx.guideUnitKind,
      fallbackChunkText: ctx.fallbackChunkText,
      verbatimKind: ctx.verbatimKind,
      verbatimText: ctx.verbatimText,
      correctionNote: ctx.correctionNote,
      guideExplanation: ctx.guideExplanation,
      guideError: ctx.guideError,
      marks: ctx.marks,
      options: options,
      stimulusText: stimulus,
      stimulusRef: ctx.stimulusRef,
    ),
    reason: grounding.reason,
  );
}

/// Honest reply for a guide chat whose question context is
/// missing or unusable — the caller shows this INSTEAD of
/// calling the model, so the tutor never builds an answer from
/// a wrong passage or invents options. Null = context is usable
/// (the model may be called with the full labeled context).
String? honestGuideChatReply(ChatGrounding resolved, Map<String, String> s) {
  if (!resolved.isGuide) return null;
  final ctx = resolved.grounding.context;
  if (!resolved.grounding.found ||
      ctx == null ||
      ctx.questionText.trim().isEmpty) {
    return s['guideChatNoContext']!;
  }
  if (ctx.mcqOptionsMissing) return s['guideChatNoOptions']!;
  return null;
}

Future<ChatGrounding> resolveChatGrounding(
  LessonSelection sel,
  int schoolClass,
  bool bn,
) async {
  final guideId = sel.guideQuestionId;
  if (guideId != null) {
    final grounding = await structuredExplanationService.resolveGuide(
      guideQuestionId: guideId,
      subject: sel.subject,
      schoolClass: schoolClass,
      bangla: bn,
    );
    return ChatGrounding(withChatStimulus(grounding, sel), true);
  }
  if (sel.questionId != null) {
    return ChatGrounding(await resolveLessonGrounding(sel, bn), false);
  }
  return ChatGrounding(
    await explanationService.resolve(
      subject: sel.subject,
      schoolClass: schoolClass,
      chapter: sel.chapter,
      page: sel.page,
      problem: sel.problem,
      bangla: bn,
    ),
    false,
  );
}
