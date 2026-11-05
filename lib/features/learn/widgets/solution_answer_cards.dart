// Cards split out of SolutionRenderer to keep that file
// under the 250-line rule. No rendering decisions live
// here: the caller passes the already-chosen text, sizes
// and colours; these widgets only lay them out.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';
import 'solution_blocks.dart';

/// Verbatim-question view (the toggle's question side).
class SolutionQuestionCard extends StatelessWidget {
  const SolutionQuestionCard({
    super.key,
    required this.questionText,
    required this.fontSize,
    required this.color,
  });
  final String questionText;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GuideMathText(
          text: questionText,
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }
}

/// Final-answer card at the end of an AI explanation.
class SolutionFinalAnswerCard extends StatelessWidget {
  const SolutionFinalAnswerCard({
    super.key,
    required this.label,
    required this.finalAnswer,
    required this.fontSize,
    required this.background,
    required this.foreground,
  });
  final String label;
  final String finalAnswer;
  final double fontSize;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.w700,
              fontFamily: 'HindSiliguri',
              color: foreground,
            ),
          ),
          const SizedBox(height: 8),
          SolutionBlocks(
            text: finalAnswer,
            fontSize: fontSize,
            color: foreground,
          ),
        ],
      ),
    );
  }
}
