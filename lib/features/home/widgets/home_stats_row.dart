import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../learn/widgets/digits.dart';
import '../home_design.dart';

/// Real stats only: values come from LearnStore (lessons opened,
/// chapters opened, saved questions). When nothing is saved yet
/// the values are 0 — never invented scores.
/// Every card is tappable and navigates itself (go_router), so
/// HomeScreen — at the 250-line cap — needs no change:
/// today's lessons -> /home/today-lessons, opened chapters ->
/// /home/opened-chapters, saved questions -> /saved.
/// Dashboard redesign (Phase 2): uniform Card tiles with a
/// theme-primary value, replacing the three rainbow gradients —
/// one visual language with the subject tiles.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.todayLabel,
    required this.chaptersLabel,
    required this.savedLabel,
    required this.values,
    required this.bangla,
  });
  final String todayLabel;
  final String chaptersLabel;
  final String savedLabel;
  final List<int> values; // [lessons today, chapters opened, saved]
  final bool bangla;

  Widget _stat(BuildContext context, int value, String label, String route) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Text(
                  numStr(value, bangla),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phase 17 (L5): equal heights. A long Bangla label wrapping to
    // two lines used to make only its card taller. IntrinsicHeight
    // sizes the row to the tallest card and stretch forces the other
    // cards to the same height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stat(context, values[0], todayLabel, '/home/today-lessons'),
          const SizedBox(width: HomeDesign.cardGap),
          _stat(context, values[1], chaptersLabel, '/home/opened-chapters'),
          const SizedBox(width: HomeDesign.cardGap),
          _stat(context, values[2], savedLabel, '/saved'),
        ],
      ),
    );
  }
}
