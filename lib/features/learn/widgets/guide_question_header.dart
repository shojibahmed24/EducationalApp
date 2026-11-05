// Guide answer header (2026-11-01): chapter, question type,
// printed marks, and model-test set — ONLY from row metadata.
// Board/year/question numbers are absent from row metadata, so
// they are never shown (nothing is invented here).
// Passage phase (2026-11-01): when the row carries stimulus
// text or a passage source ref, the pinned block renders below
// the meta line (GuideStimulusBlock); rows without either
// render exactly as before.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import 'guide_stimulus_block.dart';

class GuideQuestionHeader extends StatelessWidget {
  const GuideQuestionHeader({
    super.key,
    required this.question,
    required this.chapterNumber,
    required this.fontSize,
    required this.s,
    required this.color,
    this.showStimulus = true,
  });
  final GuideBankQuestion question;
  final int chapterNumber;
  final double fontSize;
  final Map<String, String> s;
  final Color color;

  /// False in the grouped creative view, where the stimulus is
  /// already pinned above the part tabs (never shown twice).
  final bool showStimulus;

  String? _typeLabel(String t) {
    switch (t) {
      case 'mcq':
        return s['filterMcq'];
      case 'short':
        return s['filterShort'];
      case 'creative':
        return s['filterCreative'];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 0 = no chapter: the English flow has no chapter step and
    // passes 0, so no chapter line renders for English answers.
    // Real chapters in this param are never 0 (math flows pass
    // the selected chapter), so math lines are unaffected.
    final parts = <String>[
      if (chapterNumber != 0) '${s['chapterWord']!} $chapterNumber',
    ];
    final type = _typeLabel(question.questionType);
    if (type != null) parts.add(type);
    if (question.marks != null) {
      parts.add('${question.marks} ${s['marksWord']!}');
    }
    final setId = question.setId;
    if (setId != null && setId.isNotEmpty) {
      parts.add(
        setId.startsWith('model-test-')
            ? '${s['modelTestWord']!} ${setId.substring('model-test-'.length)}'
            : setId,
      );
    }
    final stimText = question.stimulusText;
    final stimRef = question.stimulusRef;
    final hasStimulus =
        stimText?.isNotEmpty == true || stimRef?.isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text(
            parts.join(' · '),
            style: TextStyle(
              fontSize: fontSize - 1,
              fontFamily: 'HindSiliguri',
              color: color,
            ),
          ),
        if (hasStimulus && showStimulus)
          GuideStimulusBlock(
            text: stimText,
            ref: stimRef,
            fontSize: fontSize,
            s: s,
          ),
        // Pilot (013) flag note, verbatim: a print note on the
        // row (e.g. a print anomaly). Shown subtly under the
        // meta line; never edited or invented here.
        if (question.flagNote?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              question.flagNote!,
              style: TextStyle(
                fontSize: fontSize - 2,
                fontFamily: 'HindSiliguri',
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}
