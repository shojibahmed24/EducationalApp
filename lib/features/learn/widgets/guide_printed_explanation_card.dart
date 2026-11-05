// Printed explanation card (split out of guide_answer_body.dart
// to keep that file under the 250-line rule): the guide's own
// per-question explanation paragraph, verbatim, under its own
// label. This is printed guide content, never the AI
// explanation — the AI section renders separately below.
// No logic lives here.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

class GuidePrintedExplanationCard extends StatelessWidget {
  const GuidePrintedExplanationCard({
    super.key,
    required this.explanation,
    required this.fontSize,
    required this.ls,
  });

  final String explanation;
  final double fontSize;
  final Map<String, String> ls;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ls['printedExplanation']!,
              style: TextStyle(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            GuideMathText(
              text: explanation,
              fontSize: fontSize,
              color: onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
