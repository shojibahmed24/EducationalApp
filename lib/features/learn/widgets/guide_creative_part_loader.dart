// Per-part loading for the creative grouped view (step 6).
// Mirrors GuideAnswerScreen._load for ONE part id: resolveGuide
// (45s) gives stage-1 verbatim fields + grounding. ON-DEMAND
// (2026-11-03 fix): the AI explanation does NOT run here —
// the view runs it via runCreativePartExplanation only after
// the student taps "ব্যাখ্যা দেখুন". Stage-1 is reported
// through onStage1 as soon as grounding arrives, so the view
// never hides a printed solution behind the slow AI call.
// Any failure yields a 'none' record with null grounding —
// the body then shows the honest AI-first card + failed row
// with retry, never a fake solution.
import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/explanation_service.dart';
import '../../../core/services/structured_explanation_service.dart';

/// One part's loaded state: stage-1 verbatim fields + the
/// grounding the on-demand explanation runs on (null = not
/// loaded, or failed). The AI attempt lives in the view's
/// per-part state, not here: it exists only after a tap.
class CreativePartLoad {
  const CreativePartLoad({
    required this.verbatimKind,
    required this.verbatimText,
    required this.correctionNote,
    required this.guideError,
    this.attempt,
    this.grounding,
  });
  final String verbatimKind;
  final String verbatimText;
  final String correctionNote;
  final bool guideError;
  final StructuredAttempt? attempt;
  final Grounding? grounding;

  /// True when the server marked a printable guide answer.
  bool get hasVerbatim =>
      (verbatimKind == 'guide' || verbatimKind == 'corrected') &&
      verbatimText.isNotEmpty;
}

/// Per-part UI state, owned by the grouped view (moved here
/// 2026-11-03 to keep the view under the 250-line rule).
class CreativePartState {
  bool loading = false;
  bool loaded = false;
  bool explaining = false;
  bool stage1Seen = false;
  bool explanationRequested = false;
  Grounding? grounding;
  String verbatimKind = 'none';
  String verbatimText = '';
  String correctionNote = '';
  bool guideError = false;
  StructuredAttempt? attempt;
  bool showExplanation = true;
  bool stepsOnly = false;
}

/// Called with the stage-1 record as soon as grounding lands.
typedef CreativePartStage1 = void Function(CreativePartLoad stage1);

/// Loads one part. The caller supplies subject/schoolClass via
/// the widget; tests inject a fake loader with this shape.
typedef CreativePartLoader = Future<CreativePartLoad> Function(
  GuideBankQuestion part,
  bool bn,
  CreativePartStage1 onStage1,
);

Future<CreativePartLoad> defaultCreativePartLoader({
  required GuideBankQuestion part,
  required String subjectId,
  required int schoolClass,
  required bool bn,
  required CreativePartStage1 onStage1,
}) async {
  const none = CreativePartLoad(
    verbatimKind: 'none',
    verbatimText: '',
    correctionNote: '',
    guideError: false,
  );
  Grounding? grounding;
  try {
    grounding = await structuredExplanationService
        .resolveGuide(
          guideQuestionId: part.id,
          subject: subjectId,
          schoolClass: schoolClass,
          bangla: bn,
        )
        .timeout(const Duration(seconds: 45));
  } catch (_) {
    return none;
  }
  if (!grounding.found || grounding.context == null) return none;
  final ctx = grounding.context!;
  final stage1 = CreativePartLoad(
    verbatimKind: ctx.verbatimKind,
    verbatimText: ctx.verbatimText,
    correctionNote: ctx.correctionNote,
    guideError: ctx.guideError,
    grounding: grounding,
  );
  onStage1(stage1);
  return stage1;
}

/// Runs one part's explanation (view calls this ONLY after the
/// student taps "ব্যাখ্যা দেখুন"). Failure yields null, never a
/// fabricated explanation; the section then shows failed + retry.
Future<StructuredAttempt?> runCreativePartExplanation(
  Grounding grounding,
  bool bn,
) async {
  try {
    return await structuredExplanationService
        .explainStructured(grounding: grounding, style: 'steps', bangla: bn)
        .timeout(const Duration(seconds: 120));
  } catch (_) {
    return null;
  }
}
