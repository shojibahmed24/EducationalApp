// Per-question report button. No server endpoint exists for guide
// reports today, so submission is LOCAL capture only (outbox in
// GuideBankService) and the confirmation says so plainly — the UI
// must never claim a report was "sent" to a server that is not
// there. Audit 2026-10-29: no textbook error-report backend was
// found to reuse, so this is the honest local-only path.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/guide_bank_service.dart';

class GuideReportButton extends StatelessWidget {
  const GuideReportButton({
    super.key,
    required this.question,
    required this.subjectId,
    required this.chapterNumber,
    required this.s,
  });
  final GuideBankQuestion question;
  final String subjectId;
  final int chapterNumber;
  final Map<String, String> s;

  Future<void> _openSheet(BuildContext context) async {
    var reason = 'wrong-key';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['reportTitle']!,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: Text(s['reportWrongKey']!),
                    value: 'wrong-key',
                    groupValue: reason,
                    onChanged: (v) => setState(() => reason = v!),
                  ),
                  RadioListTile<String>(
                    title: Text(s['reportWrongChapter']!),
                    value: 'wrong-chapter',
                    groupValue: reason,
                    onChanged: (v) => setState(() => reason = v!),
                  ),
                  RadioListTile<String>(
                    title: Text(s['reportUnreadable']!),
                    value: 'unreadable',
                    groupValue: reason,
                    onChanged: (v) => setState(() => reason = v!),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(s['reportSubmit']!),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await guideBankService.submitReportLocal(GuideReport(
      questionId: question.id,
      subjectId: subjectId,
      chapterNumber: chapterNumber,
      reason: reason,
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s['reportSavedLocal']!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined),
      tooltip: s['reportTitle'],
      onPressed: () => _openSheet(context),
    );
  }
}
