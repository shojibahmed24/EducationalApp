// Single-question body construction, split out of
// guide_answer_screen.dart to keep that file under the 250-line
// rule. Pure pass-through to GuideAnswerBody plus the on-demand
// explanation bundle (2026-11-03 fix) and the Mode G key mapping
// (list rows never carry a key index; the Mode G letter maps
// onto the list row's verbatim options). Also homes the
// screen's chat opener, group body and back navigation.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/guide_quiz_service.dart';
import '../../core/services/structured_explanation_service.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';
import 'widgets/guide_answer_body.dart';
import 'widgets/guide_creative_answer_view.dart';
import 'widgets/guide_explanation_section.dart';

/// Ask-AI: opens /lesson/chat grounded in this exact guide
/// row (Mode G via guideQuestionId, never textbook page 0).
/// Full question context rides along (2026-11-03 chat fix):
/// verbatim options + the stimulus owned by THIS question
/// (stimulusQuestionId == q.id), so the tutor can never see
/// another question's passage or a stimulus without options.
void openGuideChat(BuildContext context, GuideBankQuestion q) {
  final stim = GuideAnswerHolder.chatStimulus(q);
  LessonSelectionHolder.set(LessonSelection(
    subject: GuideAnswerHolder.subjectId, chapter: GuideAnswerHolder.chapterNumber,
    page: 0, problem: 0, queryText: q.questionText,
    schoolClass: GuideAnswerHolder.schoolClass,
    guideQuestionId: q.id, stimulusText: stim.isNotEmpty ? stim : null,
    stimulusQuestionId: stim.isNotEmpty ? q.id : null,
    guideOptions: q.options,
    returnTo: '/guide-answer'));
  context.go('/lesson/chat');
}

/// Grouped view, or null for the single-question body.
Widget? guideGroupBody(
  BuildContext context,
  bool bn,
  Map<String, String> s,
  Map<String, String> ls,
) {
  final group = GuideAnswerHolder.group;
  if (group == null || group.isEmpty) return null;
  return GuideCreativeAnswerView(
    parts: group, stimulusText: GuideAnswerHolder.stimulusText,
    subjectId: GuideAnswerHolder.subjectId,
    chapterNumber: GuideAnswerHolder.chapterNumber,
    schoolClass: GuideAnswerHolder.schoolClass,
    bn: bn, s: s, ls: ls, onAskAi: (q) => openGuideChat(context, q),
  );
}

/// Back returns to the new-flow list that opened this answer
/// (holder.returnTo), never the deleted /guide-bank route.
void goGuideBack(BuildContext context) => context.go(GuideAnswerHolder.returnTo);

/// List-row key text: indexed option when the row itself is
/// keyed, else its answerKeyText, else null.
String? _keyText(GuideBankQuestion q) {
  if (q.hasKey) return q.options[q.correctOptionIndex!];
  if (q.answerKeyText.isNotEmpty) return q.answerKeyText;
  return null;
}

/// Builds the single-question body for [q]. [modeGOptions] are
/// the options Mode G returned; the explanation guard treats an
/// MCQ as option-less only when BOTH the list row and Mode G
/// carry no options.
Widget guideAnswerScreenBody({
  required GuideBankQuestion q,
  required bool bn,
  required Map<String, String> s,
  required Map<String, String> ls,
  required StructuredAttempt? attempt,
  required String answerKeyLetter,
  required List<String> modeGOptions,
  required double fontSize,
  required VoidCallback onFontSmaller,
  required VoidCallback onFontLarger,
  required String verbatimKind,
  required String verbatimText,
  required String guideExplanation,
  required String correctionNote,
  required bool guideError,
  required bool showExplanation,
  required bool explanationRequested,
  required bool explaining,
  required bool stepsOnly,
  required VoidCallback onExplainDetailed,
  required VoidCallback onExplainSteps,
  required VoidCallback onRequestExplanation,
  required VoidCallback onAskAi,
  required String subjectId,
  required int chapterNumber,
}) {
  // Mode G key letter -> option index (list rows never carry
  // one); bounds-checked by guideKeyIndex, null when unknown.
  final correctIndex = guideKeyIndex(answerKeyLetter, q.options.length);
  // Mode G key letter surfaces here (list rows never carry a
  // key): option text when indexed, else the letter itself —
  // so a keyed row never shows the misleading no-key note.
  final keyText = correctIndex != null
      ? q.options[correctIndex]
      : (answerKeyLetter.isNotEmpty ? answerKeyLetter : _keyText(q));
  final chips = <String>[ls['sourceGuideQuestion']!];
  if (keyText != null) chips.add(ls['sourceGuideKey']!);
  chips.add(ls['sourceAiExplanation']!);
  final unavailable = q.questionType == 'mcq' &&
      q.options.isEmpty &&
      modeGOptions.isEmpty;
  return GuideAnswerBody(
    q: q,
    attempt: attempt,
    keyText: keyText,
    correctOptionIndex: correctIndex,
    chips: chips,
    fontSize: fontSize,
    onFontSmaller: onFontSmaller,
    onFontLarger: onFontLarger,
    verbatimKind: verbatimKind,
    verbatimText: verbatimText,
    guideExplanation: guideExplanation,
    correctionNote: correctionNote,
    guideError: guideError,
    showExplanation: showExplanation,
    stepsOnly: stepsOnly,
    onExplainDetailed: onExplainDetailed,
    onExplainSteps: onExplainSteps,
    explanation: ExplanationSectionInput(
      requested: explanationRequested,
      pending: explaining,
      unavailable: unavailable,
      onRequest: onRequestExplanation,
      onRetry: onRequestExplanation,
    ),
    onAskAi: onAskAi,
    subjectId: subjectId,
    chapterNumber: chapterNumber,
    bn: bn,
    s: s,
    ls: ls,
  );
}
