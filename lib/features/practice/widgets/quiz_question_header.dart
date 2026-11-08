import 'package:flutter/material.dart';

import 'package:yes_sir_ai/theme/app_theme.dart';

/// Quiz header: "প্রশ্ন ৩/২০" + count-up clock, a slim progress bar
/// and the chapter line. UI-only; every string comes in from the
/// screen. The clock listens to its own [elapsed] notifier, so only
/// the small clock chip repaints each second (the whole question
/// screen used to rebuild every second via setState).
class QuizQuestionHeader extends StatelessWidget {
  const QuizQuestionHeader({
    super.key,
    required this.label,
    required this.progress,
    required this.elapsed,
    required this.chapter,
  });

  final String label; // already localized, e.g. "প্রশ্ন ৩/২০"
  final double progress; // 0..1
  final ValueListenable<int> elapsed;
  final String chapter;

  static String clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.headlineMedium),
              ),
              ValueListenableBuilder<int>(
                valueListenable: elapsed,
                builder: (context, seconds, _) =>
                    Chip(label: Text(clock(seconds))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(chapter, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
