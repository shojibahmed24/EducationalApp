// Guide key card (split out of guide_answer_body.dart to keep
// that file under the 250-line rule): the "correct answer"
// label plus the key text, verbatim. No logic lives here.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

class GuideKeyCard extends StatelessWidget {
  const GuideKeyCard({
    super.key,
    required this.keyText,
    required this.fontSize,
    required this.ls,
  });

  final String keyText;
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
              ls['correctAnswer']!,
              style: TextStyle(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            GuideMathText(
              text: keyText,
              fontSize: fontSize,
              color: onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
