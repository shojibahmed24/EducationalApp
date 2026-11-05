// Lesson style regeneration, split out of lesson_screen.dart
// to keep it under the 250-line limit. Pure decision logic:
// no context, no navigation, no setState — the screen applies
// the returned state and handles routing/snackbars itself.
// Source honesty lives here: demo text is 'demo', failed-AI
// book text is 'unverified', live AI is 'live'. Nothing ever
// returns 'verified'.
import '../../core/models/solution_model.dart';
import '../../core/services/explanation_service.dart';
import '../../core/services/structured_explanation_service.dart';
import 'lesson_legacy_style.dart';
import 'lesson_selection.dart';

/// Outcome of one style regeneration.
class LessonStyleResult {
  /// 'ok' | 'noMatch' | 'serverKeyMissing' | 'failed'.
  /// 'failed' covers both legacy 'fallback' (book text shown)
  /// and legacy 'failed' (no text): the screen shows the
  /// aiFailed notice for both, as before.
  final String outcome;
  final String? displayText;
  final StructuredSolution? solution;
  final String? fallbackText;
  final String? keyMismatchKey;
  final String source; // live | demo | unverified

  /// Attribution from the Edge response for a live AI
  /// result (see GenResult); 'unknown' otherwise. The
  /// screen passes it to LessonAnswerBody, never the
  /// selected provider.
  final String aiProvider;
  final String? aiModel;
  const LessonStyleResult({
    required this.outcome,
    this.displayText,
    this.solution,
    this.fallbackText,
    this.keyMismatchKey,
    required this.source,
    this.aiProvider = 'unknown',
    this.aiModel,
  });
}

Future<LessonStyleResult> runLessonStyle({
  required Grounding? grounding,
  required LessonSelection sel,
  required String style,
  required bool bn,
}) async {
  // Structured first — ungrounded input is refused outright.
  final g = grounding;
  if (g != null && g.found) {
    final attempt = await structuredExplanationService.explainStructured(
      grounding: g,
      style: style,
      bangla: bn,
    );
    if (attempt.status == StructuredStatus.ok &&
        attempt.solution != null) {
      return LessonStyleResult(
        outcome: 'ok',
        solution: attempt.solution,
        source: 'live',
        aiProvider: attempt.aiProvider,
        aiModel: attempt.aiModel,
      );
    }
    if (attempt.status == StructuredStatus.keyMismatch) {
      return LessonStyleResult(
        outcome: 'ok',
        keyMismatchKey: attempt.storedKey,
        source: 'live',
      );
    }
    if (attempt.rawText.isNotEmpty) {
      return LessonStyleResult(
        outcome: 'ok',
        fallbackText: attempt.rawText,
        source: 'live',
        aiProvider: attempt.aiProvider,
        aiModel: attempt.aiModel,
      );
    }
    // Structured unavailable: fall through to the legacy path.
  }
  final legacy = await applyLegacyStyle(sel: sel, style: style, bn: bn);
  switch (legacy.outcome) {
    case 'noMatch':
      return const LessonStyleResult(
        outcome: 'noMatch',
        source: 'unverified',
      );
    case 'found':
    case 'demo':
      return LessonStyleResult(
        outcome: 'ok',
        displayText: legacy.text,
        source: legacy.outcome == 'demo' ? 'demo' : 'live',
      );
    case 'fallback':
      return LessonStyleResult(
        outcome: 'failed',
        displayText: legacy.text,
        source: 'unverified',
      );
    case 'serverKeyMissing':
      return const LessonStyleResult(
        outcome: 'serverKeyMissing',
        source: 'unverified',
      );
    default:
      return const LessonStyleResult(
        outcome: 'failed',
        source: 'unverified',
      );
  }
}
