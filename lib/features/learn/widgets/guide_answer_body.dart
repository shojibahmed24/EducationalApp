// Guide answer body (split from guide_answer_screen.dart to keep
// both files under the 250-line rule): header, question card,
// MCQ options card, key card, printed explanation, verbatim +
// explanation buttons, stage-2 renderer, footer. The parent owns
// loading/attempt state; this widget only renders it (plus its
// own try-first attempt flag, reset when the question id
// changes). Verbatim text renders ONLY when the server marked it
// verbatim (parent passes kind/text from Grounding); 'none'
// shows the honest note and the explanation directly. STAGE-1
// INDEPENDENCE: question/key/verbatim render even when the AI explanation fails; failure shows ONLY in its own section.
// TRY-FIRST (2026-11-01): a keyed MCQ first shows only question
// + options; key, verbatim and explanation reveal after the
// pick. Unkeyed MCQs show options display-only; option-less MCQs show an honest notice, not a no-key note.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/punctuation_score.dart';
import '../../../core/services/structured_explanation_service.dart';
import 'guide_answer_footer.dart';
import 'guide_explanation_section.dart';
import 'guide_key_card.dart';
import 'guide_mcq_no_options_card.dart';
import 'guide_mcq_options_card.dart';
import 'guide_printed_explanation_card.dart';
import 'guide_punctuation_check.dart';
import 'guide_question_header.dart';
import 'guide_translated_math_text.dart';
import 'verbatim_answer_card.dart';

class GuideAnswerBody extends StatefulWidget {
  const GuideAnswerBody({
    super.key,
    required this.q,
    required this.attempt,
    required this.keyText,
    this.correctOptionIndex,
    required this.chips,
    required this.fontSize,
    required this.onFontSmaller,
    required this.onFontLarger,
    required this.verbatimKind,
    required this.verbatimText,
    this.guideExplanation = '',
    required this.correctionNote,
    required this.guideError,
    required this.showExplanation,
    required this.stepsOnly,
    required this.onExplainDetailed,
    required this.onExplainSteps,
    required this.explanation,
    this.showStimulus = true,
    this.onAskAi,
    required this.subjectId,
    required this.chapterNumber,
    required this.bn,
    required this.s,
    required this.ls,
  });

  final GuideBankQuestion q;
  final StructuredAttempt? attempt;
  final String? keyText;

  /// Mode G key letter mapped to an option index (single view
  /// only; null = unknown — list rows never carry an index).
  final int? correctOptionIndex;
  final List<String> chips;
  final double fontSize;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;
  final String verbatimKind;
  final String verbatimText;
  // Printed explanation from Mode G (migration 017); '' = none.
  final String guideExplanation;
  final String correctionNote;
  final bool guideError;
  final bool showExplanation;

  /// On-demand explanation state (button / pending / result),
  /// owned by the parent screen (2026-11-03 fix).
  final ExplanationSectionInput explanation;
  final bool stepsOnly;
  final VoidCallback onExplainDetailed;
  final VoidCallback onExplainSteps;

  /// False in the grouped view: the stimulus is pinned above.
  final bool showStimulus;

  /// Ask-AI below the explanation area (step 6); null = no button.
  final VoidCallback? onAskAi;
  final String subjectId;
  final int chapterNumber;
  final bool bn;
  final Map<String, String> s;
  final Map<String, String> ls;

  @override
  State<GuideAnswerBody> createState() => _GuideAnswerBodyState();
}

class _GuideAnswerBodyState extends State<GuideAnswerBody> {
  bool _attempted = false;

  @override
  void didUpdateWidget(GuideAnswerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.q.id != widget.q.id) _attempted = false;
  }

  GuideBankQuestion get _q => widget.q;

  /// Try-first applies only to a keyed MCQ with options: the
  /// answer area stays hidden until the student picks.
  bool get _tryFirst =>
      _q.questionType == 'mcq' &&
      _q.options.isNotEmpty &&
      widget.correctOptionIndex != null &&
      widget.correctOptionIndex! >= 0 &&
      widget.correctOptionIndex! < _q.options.length;

  bool get _mcqNoOptions => _q.questionType == 'mcq' && _q.options.isEmpty;

  bool get _revealed => !_tryFirst || _attempted;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final fontSize = widget.fontSize;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GuideQuestionHeader(
          question: _q,
          chapterNumber: widget.chapterNumber,
          fontSize: fontSize,
          s: widget.s,
          color: onVariant,
          showStimulus: widget.showStimulus,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GuideTranslatedMathText(
              text: _q.questionText,
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: onSurface,
              // English only: other subjects always render the original.
              translate: widget.subjectId == 'english',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_q.questionType == 'mcq' && _q.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GuideMcqOptionsCard(
              key: ValueKey('mcq:${_q.id}'),
              options: _q.options,
              correctOptionIndex:
                  _tryFirst ? widget.correctOptionIndex : null,
              fontSize: fontSize,
              s: widget.s,
              onAttempted: () => setState(() => _attempted = true),
            ),
          ),
        if (_mcqNoOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GuideMcqNoOptionsCard(fontSize: fontSize, s: widget.s),
          ),
        if (_revealed) ...[
          if (widget.keyText != null)
            GuideKeyCard(
              keyText: widget.keyText!,
              fontSize: fontSize,
              ls: widget.ls,
            )
          else if (_q.questionType == 'mcq' && !_mcqNoOptions) // MCQ-only: creative/short rows have no key concept, so a missing key never shows the note there.
            Text(widget.ls['noKeyNote']!),
          if (widget.attempt != null &&
              widget.attempt!.status == StructuredStatus.keyMismatch) ...[
            const SizedBox(height: 8),
            Text(widget.ls['keyMismatchNote']!),
          ],
          const SizedBox(height: 12),
          VerbatimAnswerCard(
            kind: widget.verbatimKind,
            text: widget.verbatimText,
            correctionNote: widget.correctionNote,
            guideError: widget.guideError,
            fontSize: fontSize,
            s: widget.s,
            explanationShown: widget.showExplanation,
            onExplainDetailed: widget.onExplainDetailed,
            onExplainSteps: widget.onExplainSteps,
            translate: widget.subjectId == 'english',
          ),
          if (widget.guideExplanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            GuidePrintedExplanationCard(
              explanation: widget.guideExplanation,
              fontSize: fontSize,
              ls: widget.ls,
            ),
          ],
          const SizedBox(height: 12),
          // Q9 self-check: punctuation rows with marks in the
          // key passage only; guide_error rows never score.
          if (_q.section == 'punctuation' &&
              !widget.guideError &&
              widget.keyText != null &&
              extractPunctuationMarks(widget.keyText!).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GuidePunctuationCheck(
                keyText: widget.keyText!,
                maxMarks: _q.marks ?? 5,
                fontSize: fontSize,
                ls: widget.ls,
              ),
            ),
        ],
        if (widget.showExplanation && _revealed)
          GuideExplanationSection(
            attempt: widget.attempt,
            question: _q,
            chips: widget.chips,
            fontSize: fontSize,
            s: widget.s,
            ls: widget.ls,
            stepsOnly: widget.stepsOnly,
            explanation: widget.explanation,
          ),
        GuideAnswerFooter(
          question: _q,
          subjectId: widget.subjectId,
          chapterNumber: widget.chapterNumber,
          s: widget.s,
          ls: widget.ls,
          onFontSmaller: widget.onFontSmaller,
          onFontLarger: widget.onFontLarger,
          onAskAi: widget.onAskAi,
        ),
      ],
    );
  }
}
