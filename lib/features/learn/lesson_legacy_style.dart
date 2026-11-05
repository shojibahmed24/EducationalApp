// Legacy single-text style path for the lesson screen, split
// out to keep lesson_screen.dart under the 250-line file limit.
// No context, no navigation here: the caller handles no-match
// routing and snackbars from the returned outcome.
import '../../core/services/ai_text_service.dart';
import 'lesson_selection.dart';

/// Outcome of one legacy style regeneration.
class LegacyStyleResult {
  final String outcome; // found | demo | fallback | noMatch | failed
  // 'serverKeyMissing' = the Edge OPENROUTER secret is not set.
  final String text;
  const LegacyStyleResult({required this.outcome, this.text = ''});
}

Future<LegacyStyleResult> applyLegacyStyle({
  required LessonSelection sel,
  required String style,
  required bool bn,
}) async {
  final result = await aiTextService.explain(
    subject: sel.subject,
    chapter: sel.chapter,
    page: sel.page,
    problem: sel.problem,
    style: style,
    bangla: bn,
  );
  if (result.serverKeyMissing) {
    return const LegacyStyleResult(outcome: 'serverKeyMissing');
  }
  switch (result.outcome) {
    case AiTextOutcome.noMatch:
      return const LegacyStyleResult(outcome: 'noMatch');
    case AiTextOutcome.found:
      return LegacyStyleResult(
        outcome: 'found',
        text: bn ? result.lesson!.answerBn : result.lesson!.answerEn,
      );
    case AiTextOutcome.notConfigured:
      // DEMO restyle of GROUNDED text only — never a substitute.
      final grounded =
          bn ? result.lesson!.answerBn : result.lesson!.answerEn;
      return LegacyStyleResult(
        outcome: 'demo',
        text: transformDemo(grounded, style, bn),
      );
    case AiTextOutcome.failed:
      final fallback =
          bn ? result.lesson!.answerBn : result.lesson!.answerEn;
      if (fallback.isEmpty) {
        return const LegacyStyleResult(outcome: 'failed');
      }
      return LegacyStyleResult(outcome: 'fallback', text: fallback);
  }
}
