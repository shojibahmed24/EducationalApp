// Always-visible jump bar for the English reader (plan §8).
// One chip per question group; a tap jumps in one leap to
// that group's first part. Current = filled, seen = tonal,
// unseen = outlined. Horizontally scrollable so long group
// lists (poem tests) never overflow. Never hidden.
import 'package:flutter/material.dart';

class EnglishReaderJumpBar extends StatelessWidget {
  const EnglishReaderJumpBar({
    super.key,
    required this.labels,
    required this.current,
    required this.seen,
    required this.onJump,
  });
  final List<String> labels;
  final int current;
  final Set<int> seen;
  final void Function(int groupIndex) onJump;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(labels[i]),
                  selected: i == current,
                  onSelected: (_) => onJump(i),
                  backgroundColor: seen.contains(i)
                      ? cs.secondaryContainer
                      : null,
                  labelStyle: TextStyle(
                      fontFamily: 'HindSiliguri',
                      color: i == current
                          ? cs.onPrimary
                          : cs.onSurface),
                  selectedColor: cs.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
