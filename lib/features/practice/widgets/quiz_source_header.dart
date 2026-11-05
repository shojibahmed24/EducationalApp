// Quiz source header (Phase 2, plan §2 step 2): the source
// label is ALWAYS shown (guide / bank), never silent. A short
// guide set adds an honest note + an explicit bank button (the
// user's choice, never an auto-substitution). Revision sets
// show nothing (they are the user's own wrong answers, not a
// source pool). Theme-aware: chip/card colours come from the
// theme, never hardcoded.
import 'package:flutter/material.dart';

class QuizSourceHeader extends StatelessWidget {
  const QuizSourceHeader({
    super.key,
    required this.source,
    required this.shortfall,
    required this.count,
    required this.isRevision,
    required this.s,
    this.onBankSet,
  });

  /// PracticeSession.quizSource: 'guide' | 'bankFallback'.
  final String source;
  final int shortfall;
  final int count;
  final bool isRevision;
  final Map<String, String> s;
  final VoidCallback? onBankSet;

  @override
  Widget build(BuildContext context) {
    if (isRevision) return const SizedBox.shrink();
    final isGuide = source == 'guide';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Chip(
            label: Text(
                isGuide ? s['quizSourceGuide']! : s['quizSourceBank']!),
          ),
          const SizedBox(width: 8),
          Text('$count ${s['quizCountSuffix']!}',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        if (shortfall > 0) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['quizShortNote']!.replaceAll('{n}', '$shortfall')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onBankSet,
                    child: Text(s['quizBankButton']!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
