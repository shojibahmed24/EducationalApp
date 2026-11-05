// Source chips row for the answer screen: textbook vs guide
// vs AI labels, so the student always sees what each part is.
// Labels come from the lesson strings (page-wise i18n).
// These are STATIC attribution, not toggles: they are
// deliberately smaller and fainter than the ChoiceChip toggles
// in SolutionRenderer, so the two can never be confused.
import 'package:flutter/material.dart';

class SolutionSourceChips extends StatelessWidget {
  const SolutionSourceChips({super.key, required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (l) => Chip(
              label: Text(l, style: TextStyle(fontSize: 12, color: muted)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }
}
