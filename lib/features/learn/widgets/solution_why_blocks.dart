// MCQ-only explanation blocks (ken sothik / bakigulo ken bhul).
// Split from SolutionRenderer to keep it under the 250-line cap.
// The caller gates on isMcq, so a creative/short explanation
// never shows option reasoning, even when the model fills
// those fields. A block renders only when its text exists.
import 'package:flutter/material.dart';

import '../../../core/models/solution_model.dart';
import 'solution_blocks.dart';

class SolutionWhyBlocks extends StatelessWidget {
  const SolutionWhyBlocks({
    super.key,
    required this.solution,
    required this.fontSize,
    required this.s,
    required this.onSurface,
  });
  final StructuredSolution solution;
  final double fontSize;
  final Map<String, String> s;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (solution.whyCorrect != null) ...[
          Text(
            s['whyCorrect']!,
            style: TextStyle(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              fontFamily: 'HindSiliguri',
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          SolutionBlocks(
            text: solution.whyCorrect!,
            fontSize: fontSize,
          ),
          const SizedBox(height: 12),
        ],
        if (solution.whyOthersWrong != null) ...[
          Text(
            s['whyOthersWrong']!,
            style: TextStyle(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              fontFamily: 'HindSiliguri',
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          SolutionBlocks(
            text: solution.whyOthersWrong!,
            fontSize: fontSize,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
