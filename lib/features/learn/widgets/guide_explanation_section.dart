// Guide explanation section, split out of guide_answer_body.dart
// to keep that file under the 250-line rule. Renders the
// stage-2 AI explanation (structured renderer), a pending row
// while it runs, prose fallback when unstructured, or a failed
// row with retry — never a screen hiding the stage-1 cards.
// ON-DEMAND (2026-11-03 fix): no auto-generation — the section
// first shows a "ব্যাখ্যা দেখুন" button and calls the model
// only after the student taps it. An MCQ whose options never
// arrived shows the honest not-available note, never a call.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/explanation_script_guard.dart';
import '../../../core/services/structured_explanation_service.dart';
import 'guide_message_state.dart';
import 'solution_renderer.dart';

/// On-demand state for the AI explanation section. The parent
/// owns the state; this widget only renders it.
class ExplanationSectionInput {
  const ExplanationSectionInput({
    required this.requested,
    required this.pending,
    required this.unavailable,
    required this.onRequest,
    required this.onRetry,
  });

  /// True once the student tapped "View explanation" (or retry).
  final bool requested;

  /// True while a requested explanation is running.
  final bool pending;

  /// True for an MCQ whose options genuinely never arrived:
  /// no call may run; the honest note shows instead.
  final bool unavailable;
  final VoidCallback onRequest;
  final VoidCallback onRetry;
}

class GuideExplanationSection extends StatelessWidget {
  const GuideExplanationSection({
    super.key,
    required this.attempt,
    required this.question,
    required this.chips,
    required this.fontSize,
    required this.s,
    required this.ls,
    required this.stepsOnly,
    required this.explanation,
  });
  final StructuredAttempt? attempt;
  final GuideBankQuestion question;
  final List<String> chips;
  final double fontSize;
  final Map<String, String> s;
  final Map<String, String> ls;
  final bool stepsOnly;
  final ExplanationSectionInput explanation;

  @override
  Widget build(BuildContext context) {
    final failed =
        attempt == null || attempt!.status == StructuredStatus.failed;
    // Garbled prose fallback must never reach the student: a
    // failed attempt whose raw text carries mixed-script or
    // foreign-script garbage shows the failed row instead.
    final proseFallback = attempt != null &&
            attempt!.status == StructuredStatus.failed &&
            attempt!.rawText.isNotEmpty &&
            !explanationHasScriptGarbage(attempt!.rawText)
        ? attempt!.rawText
        : null;
    if (explanation.unavailable) {
      return Text(s['explanationUnavailableOptions']!);
    }
    if (!explanation.requested) {
      return OutlinedButton(
        onPressed: explanation.onRequest,
        child: Text(s['viewExplanation']!),
      );
    }
    if (explanation.pending) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(s['explanationLoading']!),
        ],
      );
    }
    // A non-failed attempt with no solution and no usable raw
    // text (a key-mismatch draft discarded twice) must never
    // render as a blank area under the toggle: the honest note
    // with retry shows instead.
    if (!failed &&
        attempt!.solution == null &&
        attempt!.rawText.trim().isEmpty) {
      return GuideMessageState(
        title: s['explanationKeyMismatch']!,
        buttonLabel: s['retry']!,
        onPressed: explanation.onRetry,
      );
    }
    if (!failed) {
      return SolutionRenderer(
        key: ValueKey('guide:${question.id}'),
        solution: attempt!.solution,
        isMcq: question.questionType == 'mcq',
        sourceChips: chips,
        fontSize: fontSize,
        s: ls,
        marksPrinted: question.marks != null,
        hideSummary: stepsOnly,
        fallbackText: attempt!.solution == null ? attempt!.rawText : null,
        questionText: question.questionText,
        questionLabel: ls['sourceGuideQuestion']!,
        explanationLabel: ls['sourceAiExplanation']!,
        aiProvider: attempt!.aiProvider,
        aiModel: attempt!.aiModel,
      );
    }
    if (proseFallback != null) {
      return SolutionRenderer(
        key: ValueKey('guide-prose:${question.id}'),
        solution: null,
        isMcq: question.questionType == 'mcq',
        sourceChips: chips,
        fontSize: fontSize,
        s: ls,
        marksPrinted: question.marks != null,
        fallbackText: proseFallback,
        questionText: question.questionText,
        questionLabel: ls['sourceGuideQuestion']!,
        explanationLabel: ls['sourceAiExplanation']!,
        aiProvider: attempt!.aiProvider,
        aiModel: attempt!.aiModel,
      );
    }
    return GuideMessageState(
      title: s['answerFailed']!,
      buttonLabel: s['retry']!,
      onPressed: explanation.onRetry,
    );
  }
}
