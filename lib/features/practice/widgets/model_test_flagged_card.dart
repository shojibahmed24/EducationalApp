// Flagged-question card for the model-test exam screen
// (split out to keep that screen under the 250-line cap):
// flagged list with jump chips + clear-all. Pure display;
// all state changes flow back through callbacks.
import 'package:flutter/material.dart';

class ModelTestFlaggedCard extends StatelessWidget {
  const ModelTestFlaggedCard({
    super.key,
    required this.flagged,
    required this.s,
    required this.disabled,
    required this.onClear,
    required this.onJump,
  });

  /// Sorted flagged question indexes (0-based).
  final List<int> flagged;
  final Map<String, String> s;
  final bool disabled;
  final VoidCallback onClear;
  final void Function(int index) onJump;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(s['flaggedTitle']!,
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              TextButton(
                  onPressed: disabled ? null : onClear,
                  child: Text(s['flaggedClear']!)),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: flagged
                  .map((i) => ActionChip(
                        label: Text("${s['qLabel']!} ${i + 1}"),
                        onPressed: disabled ? null : () => onJump(i),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
