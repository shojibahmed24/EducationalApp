// Guide answer footer: font-size controls, Ask-AI button, and
// the report row. Split out of guide_answer_body.dart to keep
// that file under the 250-line rule. No state lives here.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import 'guide_model_link_button.dart';
import 'guide_report_button.dart';

class GuideAnswerFooter extends StatelessWidget {
  const GuideAnswerFooter({
    super.key,
    required this.question,
    required this.subjectId,
    required this.chapterNumber,
    required this.s,
    required this.ls,
    required this.onFontSmaller,
    required this.onFontLarger,
    required this.onAskAi,
  });
  final GuideBankQuestion question;
  final String subjectId;
  final int chapterNumber;
  final Map<String, String> s;
  final Map<String, String> ls;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;

  /// Null = no Ask-AI button (group view passes its own).
  final VoidCallback? onAskAi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: onFontSmaller,
              child: Text(ls['fontSmaller']!),
            ),
            TextButton(
              onPressed: onFontLarger,
              child: Text(ls['fontLarger']!),
            ),
          ],
        ),
        if (onAskAi != null)
          OutlinedButton.icon(
              onPressed: onAskAi,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(s['askAi']!)),
        if (question.modelQuestionId != null &&
            question.modelQuestionId!.isNotEmpty)
          GuideModelLinkButton(
            modelQuestionId: question.modelQuestionId!,
            label: s['modelAnswer']!,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(s['reportTitle']!),
            GuideReportButton(
              question: question,
              subjectId: subjectId,
              chapterNumber: chapterNumber,
              s: s,
            ),
          ],
        ),
      ],
    );
  }
}
