// Extracted from quiz_question_screen.dart (audit-fix Worker C,
// split-before-touch: that file was at the 250-line cap).
// The explanation card body for one checked quiz question.
// Live / DEMO / DEMO-bank explanation text renders through the
// shared SolutionBlocks renderer, never as raw Text, so AI
// markdown (**bold**, | tables |) never reaches the screen
// raw. Code fences are stripped first: SolutionBlocks consumes
// ** and | but not ``` fence lines, so a fenced AI reply
// would otherwise still show its fences.
import 'package:flutter/material.dart';
import 'package:yes_sir_ai/core/services/math_normalizer.dart';
import 'package:yes_sir_ai/features/learn/widgets/ai_attribution_label.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_blocks.dart';

/// Drops lines that are ``` code fences (``` or ```lang).
/// Inline content is untouched; only whole fence lines go.
String stripCodeFences(String text) => text
    .split('\n')
    .where((line) => !line.trim().startsWith('```'))
    .join('\n');

class QuizExplanationBody extends StatelessWidget {
  const QuizExplanationBody({
    super.key,
    required this.loading,
    required this.kind,
    required this.text,
    required this.s,
    this.aiProvider = 'unknown',
    this.aiModel,
  });

  /// True while this question's explanation is being fetched.
  final bool loading;

  /// 'live' | 'demo' | 'demo-bank' | 'missing' |
  /// 'guideMissing' | 'serverKeyMissing' | null (not fetched yet).
  final String? kind;

  /// The explanation text, when fetched (live / demo / demo-bank).
  final String? text;

  /// Quiz-question page strings (bn or en map).
  final Map<String, String> s;

  /// Attribution from the Edge response (see GenResult).
  /// Shown only under a live explanation; demo text gets
  /// no AI label, and a stale deploy shows the unknown text.
  final String aiProvider;
  final String? aiModel;

  @override
  Widget build(BuildContext context) {
    if (loading) return Text(s['aiLoading']!);
    if (kind == 'missing') {
      return Text('${s['tipTitle']!}: ${s['notIndexed']!} ${s['askExact']!}');
    }
    if (kind == 'guideMissing') {
      return Text('${s['tipTitle']!}: ${s['quizGuideMissing']!}');
    }
    if (kind == 'serverKeyMissing') {
      return Text(s['aiServerKeyMissing']!);
    }
    if (text == null || kind == null) return Text(s['aiLoading']!);
    final label = kind == 'live'
        ? s['aiLive']!
        : kind == 'demo-bank'
            ? s['aiDemoBank']!
            : s['aiDemo']!;
    // Live AI text goes through the Phase 1 math chain
    // (normalize -> SolutionRichText inside SolutionBlocks) so
    // plain-Unicode math in the reply still typesets; DEMO
    // bank text keeps its existing rendering untouched.
    final body = kind == 'live'
        ? stripCodeFences(normalizeMathText(text!))
        : stripCodeFences(text!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SolutionBlocks(text: body, fontSize: 16),
        if (kind == 'live') ...[
          const SizedBox(height: 8),
          AiAttributionLabel(
            provider: aiProvider,
            model: aiModel,
            unknownText:
                s['aiAttributionUnknown'] ?? 'AI: unknown',
          ),
        ],
      ],
    );
  }
}

/// The checked-question card (moved out of
/// quiz_question_screen.dart to keep it under the 250-line
/// cap): correct/wrong headline + the explanation body.
class QuizCheckedCard extends StatelessWidget {
  const QuizCheckedCard({
    super.key,
    required this.correct,
    required this.s,
    required this.loading,
    required this.kind,
    required this.text,
    this.aiProvider = 'unknown',
    this.aiModel,
  });
  final bool correct;
  final Map<String, String> s;
  final bool loading;
  final String? kind;
  final String? text;
  final String aiProvider;
  final String? aiModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              correct ? s['correctMsg']! : s['wrongMsg']!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            QuizExplanationBody(
              loading: loading,
              kind: kind,
              text: text,
              s: s,
              aiProvider: aiProvider,
              aiModel: aiModel,
            ),
          ],
        ),
      ),
    );
  }
}
