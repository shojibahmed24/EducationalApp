// Verbatim-first stage 1 (2026-10-31): the guide's own answer,
// shown BEFORE the AI explanation. Rendered ONLY when the server
// explicitly marks it verbatim (kind 'guide' or 'corrected') —
// the caller must never pass hidden grounding text here.
// AI-first fallback (2026-10-31): when there is no trusted
// verbatim text ('none'), the first card is an AI answer card —
// the AI explanation below it IS the answer shown first, and
// the card says plainly that it is AI-written, never the
// guide's text. Uncorrected error rows say so; other rows say
// no written solution was found. Buttons reveal the stage-2
// explanation (setState only, no new AI call); the parent
// decides which explanation view (detailed vs steps-only)
// to show.
import 'package:flutter/material.dart';

import 'guide_translated_math_text.dart';

class VerbatimAnswerCard extends StatelessWidget {
  const VerbatimAnswerCard({
    super.key,
    required this.kind,
    required this.text,
    required this.correctionNote,
    required this.guideError,
    required this.fontSize,
    required this.s,
    required this.explanationShown,
    required this.onExplainDetailed,
    required this.onExplainSteps,
    this.translate = false,
  });

  /// 'guide' | 'corrected' | 'none' (server verbatimKind).
  final String kind;
  final String text;
  final String correctionNote;
  final bool guideError;
  final double fontSize;
  final Map<String, String> s;
  final bool explanationShown;
  final VoidCallback onExplainDetailed;
  final VoidCallback onExplainSteps;

  /// True only for the English flow (set by the answer body
  /// from subjectId): other subjects always render the
  /// original, whatever the translator switch says.
  final bool translate;

  bool get _hasVerbatim =>
      (kind == 'guide' || kind == 'corrected') && text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (!_hasVerbatim) {
      // AI-first fallback: the AI explanation rendered below this
      // card is the answer shown first for this question. The
      // card never claims guide provenance for it.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['aiAnswerTitle']!,
                style: TextStyle(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'HindSiliguri',
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                guideError
                    ? s['verbatimErrorNote']!
                    : s['aiAnswerNoGuideNote']!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'HindSiliguri',
                  height: 1.7,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind == 'corrected'
                      ? s['verbatimCorrectedTitle']!
                      : s['verbatimGuideTitle']!,
                  style: TextStyle(
                    fontSize: fontSize + 1,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HindSiliguri',
                    color: onSurface,
                  ),
                ),
                if (kind == 'corrected') ...[
                  const SizedBox(height: 4),
                  Text(
                    correctionNote.isNotEmpty
                        ? correctionNote
                        : s['verbatimCorrectedNote']!,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'HindSiliguri',
                      height: 1.7,
                      color: onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Math-rendered (no longer selectable: RichText
                // with math spans cannot select; rendering
                // correctness wins over copy-paste here).
                // Translated in the English flow when the
                // translator switch is on, original otherwise.
                GuideTranslatedMathText(
                  text: text,
                  fontSize: fontSize,
                  color: onSurface,
                  translate: translate,
                ),
              ],
            ),
          ),
        ),
        if (!explanationShown) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onExplainDetailed,
                child: Text(s['explainDetailed']!),
              ),
              FilledButton.tonal(
                onPressed: onExplainSteps,
                child: Text(s['explainSteps']!),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
