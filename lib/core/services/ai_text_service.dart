// Text AI via OpenRouter — thin adapter over explanation_service.
// Grounding is enforced THERE before any AI call: an ungrounded
// question returns noMatch and the UI shows the no-match screen.
// The AI is NEVER asked to guess an unindexed question, and is
// sent full book context (chapter + verbatim question text),
// not just a question title (Phase 2 / C2 fix).
import '../models/backend_models.dart';
import 'explanation_service.dart';

enum AiTextOutcome { found, noMatch, notConfigured, failed }

class AiTextResult {
  final AiTextOutcome outcome;
  final LessonResult? lesson;

  /// True when the text is DEMO (grounded local text, not live AI).
  /// The UI must label it DEMO; it must never be shown as live AI.
  final bool demo;

  /// True when the Edge OPENROUTER secret is not set. The UI must
  /// show the not-configured error, never a fabricated answer.
  final bool serverKeyMissing;
  const AiTextResult({
    required this.outcome,
    this.lesson,
    this.demo = false,
    this.serverKeyMissing = false,
  });
}

/// DEMO-only local restyle: rearranges the GROUNDED answer text
/// only — it never adds new facts, problems, or book content.
/// Used in DEMO mode (no backend). The UI labels it DEMO.
String transformDemo(String text, String style, bool bangla) {
  final sep = bangla ? '।' : '.';
  final sentences = text
      .split(sep)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (sentences.isEmpty) return text;
  switch (style) {
    case 'short':
      return '${sentences.first}$sep';
    case 'simple':
      final head = bangla ? 'সহজ করে:\n' : 'Simply:\n';
      return head + sentences.join('\n');
    case 'beautiful':
      final head = bangla ? 'চলো সহজ করে বুঝি —\n\n' : "Let's understand it nicely —\n\n";
      final tail = bangla
          ? '\n\nএই নিয়মটা মনে রাখলেই হবে।'
          : '\n\nJust remember this rule.';
      return head + sentences.join('\n\n') + tail;
    case 'steps':
      return sentences
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}$sep')
          .join('\n');
    case 'examples':
      final head = bangla
          ? 'উদাহরণ হিসেবে উপরের ধাপগুলো আবার দেখো:\n'
          : 'As an example, look at the steps above again:\n';
      return head + sentences.join('\n');
    default:
      return text;
  }
}

class AiTextService {
  Future<AiTextResult> explain({
    required String subject,
    required int chapter,
    required int page,
    required int problem,
    required String style, // short | simple | steps | examples
    bool bangla = true,
  }) async {
    final grounding = await explanationService.resolve(
      subject: subject,
      chapter: chapter,
      page: page,
      problem: problem,
      bangla: bangla,
    );
    if (!grounding.found || grounding.context == null) {
      return const AiTextResult(outcome: AiTextOutcome.noMatch);
    }
    final ctx = grounding.context!;
    final res = await explanationService.explain(
      grounding: grounding,
      style: style,
      bangla: bangla,
    );
    if (res.serverKeyMissing) {
      return AiTextResult(
        outcome: AiTextOutcome.failed,
        lesson: LessonResult(
          question: ctx.questionText,
          answerBn: '',
          answerEn: '',
          found: true,
        ),
        serverKeyMissing: true,
      );
    }
    switch (res.outcome) {
      case ExplanationOutcome.live:
        return AiTextResult(
          outcome: AiTextOutcome.found,
          lesson: LessonResult(
            question: ctx.questionText,
            answerBn: res.text,
            answerEn: res.text,
            found: true,
          ),
        );
      case ExplanationOutcome.demo:
        return AiTextResult(
          outcome: AiTextOutcome.notConfigured,
          lesson: LessonResult(
            question: ctx.questionText,
            answerBn: res.text,
            answerEn: res.text,
            found: true,
          ),
          demo: true,
        );
      case ExplanationOutcome.failed:
        // Grounded text fallback (local answer, or '' for edge rows
        // which hold no stored answer); the screen shows aiFailed.
        return AiTextResult(
          outcome: AiTextOutcome.failed,
          lesson: LessonResult(
            question: ctx.questionText,
            answerBn: ctx.localAnswer,
            answerEn: ctx.localAnswer,
            found: true,
          ),
        );
      case ExplanationOutcome.ungrounded:
        return const AiTextResult(outcome: AiTextOutcome.noMatch);
    }
  }
}

final aiTextService = AiTextService();
