// Chat marks routing, split out of chat_screen.dart to keep that
// file under the 250-line cap. A chat message that states marks
// ("মার্ক ৪") takes the STRUCTURED path — the same
// explainStructured + marksBudgetFor step budget the lesson path
// enforces — instead of the plain path's prompt-only teacher
// note. A message without stated marks keeps the plain path
// exactly (this file returns null for it and the caller runs the
// old plain explain). Marks are a length budget ONLY: they are
// never printed or displayed as printed marks, and a structured
// step's sectionMarks are deliberately dropped when rendering.
// Structured failure yields null so the caller falls back to the
// plain path (demo mode and legacy behaviour are preserved).
import '../../core/models/solution_model.dart';
import '../../core/services/chat_marks.dart';
import '../../core/services/explanation_service.dart';
import '../../core/services/structured_explanation_service.dart';
import '../../core/services/structured_parse.dart';

/// True exactly when the message takes the structured path: the
/// student stated marks in it (parseUserMarks non-null). A bare
/// number is never marks — parseUserMarks requires a marks word.
bool useStructuredChatReply(String message) => parseUserMarks(message) != null;

/// Render a structured solution as chat-bubble text (ChatMsg is
/// plain text, rendered through SolutionBlocks). Summary first
/// unless it duplicates the final answer (same guard as the
/// lesson renderer), then numbered steps, then the final answer.
/// Step sectionMarks are NEVER rendered: the budget is for answer
/// length only, never a displayed mark.
String structuredSolutionToChatText(StructuredSolution solution) {
  final parts = <String>[];
  if (!summaryEqualsFinal(solution.summary, solution.finalAnswer)) {
    parts.add(solution.summary);
  }
  for (final step in solution.steps) {
    final label = step.sectionLabel == null ? '' : '${step.sectionLabel} ';
    final head = step.title.isEmpty
        ? '${step.n}.'
        : '${step.n}. $label${step.title}';
    parts.add('$head\n${step.text}');
    // Formula box content has no bubble widget here: keep the
    // LaTeX line only when the step text does not already hold it.
    if (step.formulaLatex != null &&
        step.formulaLatex!.isNotEmpty &&
        !step.text.contains(step.formulaLatex!)) {
      parts.add(step.formulaLatex!);
    }
    if (step.table != null) {
      parts.add(step.table!.headers.join(' | '));
      for (final row in step.table!.rows) {
        parts.add(row.join(' | '));
      }
    }
  }
  if (solution.whyCorrect != null && solution.whyCorrect!.isNotEmpty) {
    parts.add(solution.whyCorrect!);
  }
  if (solution.whyOthersWrong != null && solution.whyOthersWrong!.isNotEmpty) {
    parts.add(solution.whyOthersWrong!);
  }
  parts.add(solution.finalAnswer);
  return parts.join('\n\n');
}

/// Map one structured attempt to chat text, or null when the
/// caller must fall back to the plain path. ok -> solution text;
/// keyMismatch -> the stored key (locked policy: the mismatched
/// draft is discarded and the key is shown instead); unparseable
/// prose -> its raw text; failed with no text -> null.
String? chatReplyFromStructuredAttempt(StructuredAttempt attempt) {
  if (attempt.status == StructuredStatus.ok && attempt.solution != null) {
    return structuredSolutionToChatText(attempt.solution!);
  }
  if (attempt.status == StructuredStatus.keyMismatch &&
      attempt.storedKey.isNotEmpty) {
    return attempt.storedKey;
  }
  if (attempt.rawText.isNotEmpty) return attempt.rawText;
  return null;
}

/// Plain-path outcome mapping, moved unchanged from
/// chat_screen.dart: live -> text, demo -> demo label + text,
/// server key missing -> that notice, else the verified book
/// text when present, else the generic failure notice.
String chatReplyFromPlainResult(ExplanationResult res, Map<String, String> s) {
  if (res.outcome == ExplanationOutcome.live) return res.text;
  if (res.outcome == ExplanationOutcome.demo) {
    return '${s['demoReply']!}\n${res.text}';
  }
  if (res.serverKeyMissing) return s['aiServerKeyMissing']!;
  final fallback = res.context?.localAnswer ?? '';
  return fallback.isNotEmpty ? fallback : s['aiFailed']!;
}

/// Structured-first reply for one chat message, or null when the
/// message carries no marks (plain path) or the structured
/// attempt yields nothing (plain fallback). [structuredAttempt]
/// is injectable for tests; production passes nothing and the
/// real structured service runs with the parsed marks as its
/// marksOverride budget.
Future<String?> structuredChatReply({
  required Grounding grounding,
  required bool bangla,
  required String userQuestion,
  Future<StructuredAttempt> Function(int marks)? structuredAttempt,
}) async {
  final marks = parseUserMarks(userQuestion);
  if (marks == null) return null;
  final attempt = structuredAttempt != null
      ? await structuredAttempt(marks)
      : await structuredExplanationService.explainStructured(
          grounding: grounding,
          style: 'simple',
          bangla: bangla,
          userQuestion: userQuestion,
          marksOverride: marks,
        );
  return chatReplyFromStructuredAttempt(attempt);
}
