// One guide bank row. Shows only printed evidence: a marks badge
// only when marks != null, a star only when important == true.
// A key-status label (not the key itself) tells the student
// before opening whether a stored key exists. Locked rows show a
// lock; the parent decides the tap target (answer vs paywall).
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../theme/app_theme.dart';
import 'guide_report_button.dart';

class GuideQuestionRow extends StatelessWidget {
  const GuideQuestionRow({
    super.key,
    required this.question,
    required this.locked,
    required this.s,
    required this.subjectId,
    required this.chapterNumber,
    required this.onTap,
  });
  final GuideBankQuestion question;
  final bool locked;
  final Map<String, String> s;
  final String subjectId;
  final int chapterNumber;
  final VoidCallback onTap;

  String _typeLabel() {
    switch (question.questionType) {
      case 'mcq':
        return s['filterMcq']!;
      case 'short':
        return s['filterShort']!;
      case 'creative':
        return s['filterCreative']!;
      case 'fill_blank':
        return s['filterFillBlank']!;
      default:
        return s['filterOther']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI palette (গ): the row icon carries the subject colour
    // (locked rows keep the error-red lock, unchanged).
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: ListTile(
        leading: Icon(
          locked ? Icons.lock : Icons.assignment,
          color: locked
              ? Theme.of(context).colorScheme.error
              : AppTheme.subjectColorFor(subjectId, dark: dark),
        ),
        title: Text(
          question.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Chip(label: Text(_typeLabel())),
            if (question.marks != null)
              Chip(
                label: Text(
                  '${question.marks} ${s['marksWord']!}',
                ),
              ),
            // Pilot (lesson 2.1): practice-work rows are NOT
            // textbook solutions — say so on the row itself, so
            // a student never mistakes one for the other.
            if (question.section == 'practice_work')
              Chip(label: Text(s['practiceWorkNote']!)),
            // Pilot: a paired solution exists only when the
            // server says so (true). Null/false show nothing —
            // unknown is never presented as "no solution".
            if (question.hasSolution == true)
              Chip(label: Text(s['solutionAvailable']!)),
            if (question.important)
              const Chip(
                label: Text('★'),
              ),
            // Batch 2, item 3: the key-missing chip is MCQ-only.
            // Problem/creative rows have no key BY DESIGN — their
            // answers come from an AI rewrite of the printed guide
            // solution, not from a key — so labelling every অন্যান্য
            // row 'চাবি নেই' was misleading. keyExists, not hasKey:
            // server rows carry a hasKey boolean, not a key index —
            // hasKey alone would wrongly label every keyed server
            // row as key-missing.
            if (question.questionType == 'mcq' && !question.keyExists)
              Chip(label: Text(s['keyMissing']!)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GuideReportButton(
              question: question,
              subjectId: subjectId,
              chapterNumber: chapterNumber,
              s: s,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
