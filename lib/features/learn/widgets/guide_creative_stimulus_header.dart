// Pinned stimulus header for the creative grouped view, split
// out of guide_creative_answer_view.dart to keep that file
// under the 250-line rule. Display only: the stimulus stays
// visible above the part tabs across switches.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

class GuideCreativeStimulusHeader extends StatelessWidget {
  const GuideCreativeStimulusHeader({
    super.key,
    required this.stimulusText,
    required this.fontSize,
    required this.title,
    required this.color,
  });
  final String stimulusText;
  final double fontSize;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            GuideMathText(
              text: stimulusText,
              fontSize: fontSize,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
