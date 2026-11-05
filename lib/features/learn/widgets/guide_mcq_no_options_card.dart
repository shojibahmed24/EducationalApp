// MCQ-no-options notice (split out of guide_answer_body.dart
// to keep that file under the 250-line rule): an option-less
// MCQ shows an honest notice, not a no-key note. No logic
// lives here.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

class GuideMcqNoOptionsCard extends StatelessWidget {
  const GuideMcqNoOptionsCard({
    super.key,
    required this.fontSize,
    required this.s,
  });

  final double fontSize;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GuideMathText(
          text: s['optionsMissing']!,
          fontSize: fontSize,
          color: onSurface,
        ),
      ),
    );
  }
}
