// Grounded branch of the lesson screen, split out to keep
// lesson_screen.dart under the 250-line file limit. Renders the
// structured solution (card renderer) when present, the key card
// on a key-gate mismatch, else the legacy single-card text path
// (DEMO / grounded fallback). No grounding decisions here.
import 'package:flutter/material.dart';

import '../../core/models/solution_model.dart';
import 'lesson_helpers.dart';
import 'lesson_selection.dart';
import 'widgets/lesson_action_chips.dart';
import 'widgets/lesson_step_card.dart';
import 'widgets/solution_blocks.dart';
import 'widgets/solution_renderer.dart';

class LessonAnswerBody extends StatelessWidget {
  const LessonAnswerBody({
    super.key,
    required this.s,
    required this.sel,
    required this.bn,
    required this.questionText,
    required this.sourceLabel,
    required this.fontSize,
    required this.onFontSmaller,
    required this.onFontLarger,
    required this.loading,
    required this.displayText,
    required this.solution,
    required this.fallbackText,
    required this.keyMismatchKey,
    required this.isGuide,
    required this.hasAnswerKey,
    required this.showSourceChips,
    required this.marksPrinted,
    required this.onStyle,
    required this.onPractice,
    this.aiProvider = 'unknown',
    this.aiModel,
  });
  final Map<String, String> s;
  final LessonSelection sel;
  final bool bn;
  final String questionText;
  final String sourceLabel;
  final double fontSize;
  final void Function() onFontSmaller;
  final void Function() onFontLarger;
  final bool loading;
  final String? displayText;
  final StructuredSolution? solution;
  final String? fallbackText;
  final String? keyMismatchKey;
  final bool isGuide;
  final bool hasAnswerKey;
  final bool showSourceChips;
  final bool marksPrinted;
  final void Function(String style) onStyle;
  final void Function() onPractice;

  /// Attribution from the Edge response for the AI text
  /// rendered here (see GenResult); 'unknown' on a stale
  /// deploy. Never the selected provider.
  final String aiProvider;
  final String? aiModel;

  List<String> _chips() {
    if (!showSourceChips) return [];
    if (isGuide) {
      return [
        s['sourceGuideQuestion']!,
        if (hasAnswerKey) s['sourceGuideKey']!,
        s['sourceAiExplanation']!,
      ];
    }
    return [s['sourceBookQuestion']!, s['sourceAiBook']!];
  }

  String? get _noKeyNote =>
      isGuide && !hasAnswerKey && solution != null ? s['noKeyNote'] : null;

  Widget _display(BuildContext context) {
    if (keyMismatchKey != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['correctAnswer']!,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'HindSiliguri',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                keyMismatchKey!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'HindSiliguri',
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s['keyMismatchNote']!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    if (solution != null || fallbackText != null) {
      return SolutionRenderer(
        // C3: renderer state resets when the question changes.
        key: ValueKey('lesson:${sel.key}:$questionText'),
        solution: solution,
        isMcq: false, // Lesson problems are never MCQ.
        fallbackText: fallbackText,
        sourceChips: _chips(),
        fontSize: fontSize,
        s: s,
        marksPrinted: marksPrinted,
        questionText: questionText,
        questionLabel: isGuide
            ? s['sourceGuideQuestion']!
            : s['sourceBookQuestion']!,
        explanationLabel: isGuide
            ? s['sourceAiExplanation']!
            : s['sourceAiBook']!,
        aiProvider: aiProvider,
        aiModel: aiModel,
      );
    }
    if (displayText != null) {
      // Legacy path (1.5/B-path): the raw single-card Text is
      // gone — displayText now renders through the shared block
      // renderer, so markdown never prints raw here either.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['title']!,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'HindSiliguri',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              SolutionBlocks(text: displayText!, fontSize: fontSize),
            ],
          ),
        ),
      );
    }
    if (sel.key == 'math|3|45|5') {
      return Column(
        children: [
          LessonStepCard(
            title: s['step1Title']!,
            body: s['step1Body']!,
            fontSize: fontSize,
          ),
          const SizedBox(height: 12),
          LessonStepCard(
            title: s['step2Title']!,
            body: s['step2Body']!,
            fontSize: fontSize,
          ),
        ],
      );
    }
    return LessonStepCard(
      title: s['title']!,
      body: baseLessonAnswer(sel, bn),
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(questionText, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(sourceLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: onFontSmaller,
              child: Text(s['fontSmaller']!),
            ),
            TextButton(onPressed: onFontLarger, child: Text(s['fontLarger']!)),
          ],
        ),
        if (loading) Text(s['loadingAnswer']!),
        _display(context),
        if (_noKeyNote != null) ...[
          const SizedBox(height: 12),
          Text(_noKeyNote!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 20),
        LessonActionChips(
          shorten: s['shorten']!,
          simpler: s['simpler']!,
          stepByStep: s['stepByStep']!,
          moreExamples: s['moreExamples']!,
          beautiful: s['beautiful']!,
          askInChat: s['askInChat']!,
          onStyle: onStyle,
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onPractice, child: Text(s['practiceSame']!)),
      ],
    );
  }
}
